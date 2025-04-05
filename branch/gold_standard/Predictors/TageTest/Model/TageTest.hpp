#ifndef TAGE_HPP
#define TAGE_HPP

#include "../../../include/gold_standard.hpp"
#include "../../../include/Components/lfsr.hpp"
#include "defs.h"
#include "../../Common/C++/Util.hpp"

#include <unistd.h>
#include <iostream>
#include <cassert>
#include<bitset>
#include<optional>
#include <cstdio>



/*
TAGE paper

In order to limit this phenomenon, it was proposed in [24] to include non-conditional
branches in the branch history ghist (by inserting a taken bit) and to also use a (limited)
16-bit path history phist consisting of 1 address bit per branch.

*/

#define DEBUG_PRED 0

namespace gold_standard {
    // Default values of 0
    
    #define U_COUNTER_SIZE 2
    #define COUNTER_SIZE 3
    
    constexpr uint8_t U_COUNTER_MAX = (1 << U_COUNTER_SIZE) - 1;
    constexpr uint8_t WEAK_TAKEN  = (1 << COUNTER_SIZE) / 2;
    constexpr uint8_t WEAK_NOT_TAKEN = ((1 << COUNTER_SIZE) / 2) - 1;


    #define COUNTER_MAX ((1 << COUNTER_SIZE) - 1)

    #define BIMODAL_COUNTER_SIZE 2

    #define BIMODAL_PREDICTION_BITS 13
    #define BIMODAL_HYSTERESIS_BITS 11

    #define ALT_ON_NA_BITS 4
    
    constexpr uint8_t ALT_ON_NA_MAX = (1 << ALT_ON_NA_BITS) - 1;
    constexpr uint8_t ALT_ON_NA_THRESHOLD  = (1 << ALT_ON_NA_BITS) / 2;

    constexpr uint16_t prediction_entries = (( 1 << BIMODAL_PREDICTION_BITS) / 64);
    constexpr uint16_t hysteresis_entries = (( 1 << BIMODAL_HYSTERESIS_BITS) / 64);

    // Index size, Tag size, History length
    std::bitset<GLOBAL_SIZE> global_history;
    std::bitset<PATH_HISTORY_SIZE> path_history;
    

    std::array<uint64_t, prediction_entries> bimodal_prediction_bits;
    std::array<uint64_t, hysteresis_entries> bimodal_hysteresis_bits;
    tagged_tables_type tagged_tables;
    trainingInfo last_training_data;
    uint8_t alt_on_na;
    lfsr<4> feedback_shift_register(9,9);

    constexpr table_parameters t1{9,9,5};   
    constexpr table_parameters t2{9,9,9};
    constexpr table_parameters t3{9,10,15};
    constexpr table_parameters t4{9,10,25};
    constexpr table_parameters t5{9,11,44};
    constexpr table_parameters t6{9,11,76};
    constexpr table_parameters t7{9,12,130};

    /* Remove later, debugging */
    int count = 0;
    FILE *file;

    void gold_standard_predictor::impl_initialise(){

        /* REMOVE LATER */
        
        file = fopen("error.log", "w");
        
        /* REMOVE LATER */

        tagged_tables.push_back(std::make_unique<tagged_table<t1>>());
        tagged_tables.push_back(std::make_unique<tagged_table<t2>>());
        tagged_tables.push_back(std::make_unique<tagged_table<t3>>());
        tagged_tables.push_back(std::make_unique<tagged_table<t4>>());
        tagged_tables.push_back(std::make_unique<tagged_table<t5>>());
        tagged_tables.push_back(std::make_unique<tagged_table<t6>>());
        tagged_tables.push_back(std::make_unique<tagged_table<t7>>());

        global_history.reset();
        path_history.reset();
        
        // Set to weakly taken
        bimodal_prediction_bits.fill(~(uint64_t)0);
        bimodal_hysteresis_bits.fill(0);

        alt_on_na = ALT_ON_NA_THRESHOLD;   
        std::cout << "Initialized\n";
    }

    uint8_t gold_standard_predictor::impl_predict_branch(uint64_t ip){
        
        bool found_provider = false;
        bool found_alt = false;
        int provider = 0;
        int  alt = 0;
        tagged_entry provider_entry;
        tagged_entry alt_entry;
        
        //printf("GOLD STANDARD PREDICT %d, LSFSR %d", ip)
        
        for(int i = tagged_tables.size()-1; i >= 0; i--){
            
            auto entry = tagged_tables[i]->access_entry(ip);
            if(entry.has_value()){
                if(!found_provider){
                    found_provider = true;
                    provider = i;
                    provider_entry = entry.value();
                }else if(!found_alt){
                    found_alt = true;
                    alt = i;
                    alt_entry = entry.value();
                }
            }
            debug_printf("%ld\n", ip);
        }
        
        if(found_provider){
            debug_printf("%d\n", provider_entry.counter);
        }

        // Set up training data, half of it is not really necessary
        if(!found_provider){
            last_training_data.use_bimodal = true;
            last_training_data.provider_prediction = access_bimodal_entry(ip) == 1;
            //printf("GOLD STANDARD INDEX %d %d\n", get_bimodal_index(ip).first, get_bimodal_index(ip).second);
            last_training_data.taken = last_training_data.provider_prediction;
        }else{
            if(DEBUG_PRED)
                fprintf(file,"GOLD STANDARD INDEX %d %d %d %d\n", ip, provider, tagged_tables[provider]->get_index(ip), tagged_tables[provider]->compute_tag(ip));

            last_training_data.use_bimodal = false;
            last_training_data.pred_table = provider;
            last_training_data.provider_prediction = provider_entry.counter > WEAK_NOT_TAKEN;
            last_training_data.taken = last_training_data.provider_prediction;

            if(!found_alt){
               last_training_data.alt_bimodal = true;
               last_training_data.alt_prediction = access_bimodal_entry(ip) == 1;
            }else{
                last_training_data.alt_bimodal = false;
                last_training_data.alt_table = alt;
                last_training_data.alt_prediction = alt_entry.counter > WEAK_NOT_TAKEN;
                // Is this also true if the alternative is bimodal?
                if(provider_entry.useful_counter == 0 && (provider_entry.counter == WEAK_TAKEN || provider_entry.counter == WEAK_NOT_TAKEN) && alt_on_na >= ALT_ON_NA_THRESHOLD){
                    last_training_data.taken = last_training_data.alt_prediction;
                }
            }
        }


        // DODGY - meant to be done each cycle
        //feedback_shift_register.next();

        //printf("GOLD STANDARD PRED %d %d %d %d\n", found_provider, found_alt, alt, provider);
        //printf("%d %d %d %d\n", found_provider, found_alt, alt, provider);
        //printf("GOLD STANDARD PREDICTS: %d\n",last_training_data.taken);
        return last_training_data.taken;
    }

    // Luckily updates are immediately after the predictions
    void gold_standard_predictor::impl_last_branch_result(uint64_t ip, uint64_t target, uint8_t taken, uint8_t branch_type){        
        if(DEBUG_PRED) {
            
            fprintf(file, "UPDATE %d\n", count);
            fprintf(file, "GOLD STANDARD PRED %llu %llu\n", ip, feedback_shift_register.get().to_ulong());
            fprintf(file, "GOLD STANDARD PREDICTS %d\n", last_training_data.taken);
            fprintf(file, "GOLD STANDARD ALT_ON_NA %llu\n", alt_on_na);
        }
        
        bool branch_taken = taken > 0;
        // ********* Bimodal update
        std::pair<uint32_t, uint32_t> bimodal_index = get_bimodal_index(ip);
        uint8_t counter = (get_bimodal_bit(bimodal_index.first, bimodal_prediction_bits) << 1) + get_bimodal_bit(bimodal_index.second, bimodal_hysteresis_bits);

        update_counter(counter, branch_taken, (1 << BIMODAL_COUNTER_SIZE)-1);

        set_bimodal_bit(bimodal_index.first, (counter & 2) >> 1, bimodal_prediction_bits);
        set_bimodal_bit(bimodal_index.second, counter & 1, bimodal_hysteresis_bits);

        // ******** Allocation on misprediction
        if(last_training_data.taken != branch_taken && (last_training_data.use_bimodal || (last_training_data.pred_table < tagged_tables.size()-1))){
            // On a prediction this could be brought along rather than recalculated?
            // CHECK
            
            std::vector<int> replaceable_entries{};
            // Check if there exists an entry with u = 0
            int start = last_training_data.use_bimodal ? 0 : last_training_data.pred_table+1;
            for(uint32_t i = start; i < tagged_tables.size(); i++){
                
                int t_index = tagged_tables[i]->get_index(ip);
                if(tagged_tables[i]->get_entry(t_index).useful_counter == 0){
                    replaceable_entries.push_back(i);
                }
            }
            // Decrement all entries https://inria.hal.science/hal-03408381/document
            if(replaceable_entries.size() == 0){
                for(uint32_t i = start; i < tagged_tables.size(); i++){
                    int t_index = tagged_tables[i]->get_index(ip);
                    tagged_entry tab = tagged_tables[i]->get_entry(t_index);
                    update_counter(tab.useful_counter, false, U_COUNTER_MAX);
                    tagged_tables[i]->set_entry(t_index, tab);
                }
            }else{
                
                // CHECK - Ping pong phenomenae
                uint8_t a = feedback_shift_register.get().to_ulong() & 0x7 | feedback_shift_register.get().test(3);
                uint32_t replace_table_index;
                debug_printf("Random: %d\n",a);
                if(replaceable_entries.size() == 1 || a >= 4){ // 1/2 chance
                    replace_table_index = replaceable_entries[0];
                } else if(replaceable_entries.size() == 2 || a >= 2) { //1/4 chance
                    replace_table_index = replaceable_entries[1];
                } else {
                    replace_table_index = replaceable_entries[2];
                }

                if(DEBUG_PRED)
                    fprintf(file, "GOLD STANDARD ALLOCATE FOR: %d %d %d %d\n", ip, replace_table_index, tagged_tables[replace_table_index]->get_index(ip), tagged_tables[replace_table_index]->compute_tag(ip));
                if(replace_table_index < tagged_tables.size()){
                    tagged_tables[replace_table_index]->allocate_entry(
                        ip,
                        branch_taken
                    );
                }else{
                    assert(false);
                }
                
            }
        }

        // ********* Tagged tables update
        if(!last_training_data.use_bimodal){
            std::unique_ptr<table>& pred = tagged_tables[last_training_data.pred_table];
            uint16_t index = pred->get_index(ip);
            tagged_entry t = pred->get_entry(index);
            
            if(DEBUG_PRED){
                if(last_training_data.alt_bimodal){
                    fprintf(file, "GOLD STANDARD ALT PRED BIMODAL\n");
                }else{
                    fprintf(file, "GOLD STANDARD ALT PRED TABLE %d\n", last_training_data.alt_table);
                }
                fprintf(file, "GOLD STANDARD ALT PRED TAKEN %d\n", last_training_data.alt_prediction);
                fprintf(file, "GOLD STANDARD PROVIDER ENTRY COUNTER %d\n", t.counter);
                fprintf(file, "GOLD STANDARD PROVIDER USEFUL COUNTER %d\n", t.useful_counter);
            }
            
            // Update ALT_ON_NA
            if(t.useful_counter == 0 && (t.counter == WEAK_NOT_TAKEN || t.counter == WEAK_TAKEN)){   
                if(last_training_data.alt_prediction != last_training_data.provider_prediction){
                    update_counter(alt_on_na, last_training_data.alt_prediction == branch_taken, ALT_ON_NA_MAX);
                }

            }

            // Update counter regardless
            update_counter(t.counter, branch_taken, COUNTER_MAX);
            // Update useful counters
            if(last_training_data.provider_prediction == branch_taken && last_training_data.alt_prediction != branch_taken) {
                update_counter(t.useful_counter, true, U_COUNTER_MAX);
            }else if(last_training_data.provider_prediction != branch_taken && last_training_data.alt_prediction == branch_taken) {
                update_counter(t.useful_counter, false, U_COUNTER_MAX);
            }
            pred->set_entry(index, t);
        }

        // TODO - Add reset here
        
        // Update global and path history
        if (branch_type == BRANCH_DIRECT_JUMP){
            global_history <<= 1;
            global_history.set(0, true);
        }else if(branch_type == BRANCH_CONDITIONAL){
            global_history <<= 1;
            global_history.set(0, branch_taken);
            
            path_history <<= 1;
            path_history.set(0, (bool)(ip & (1 << 5) >> 5));
        }

        for(uint32_t i = 0; i < tagged_tables.size(); i++){
            tagged_tables[i]->update_history(global_history, path_history);
        }
        
        //printf("Updated %d\n", taken);
        // DODGY - meant to be done each cycle
        feedback_shift_register.next();
        
        count++;
        fflush(file);
        return;
    }

// ****************************
// Functions relatingg to Bimodal predictor

    template <uint64_t size>
    uint8_t get_bimodal_bit(uint32_t index, std::array<uint64_t,size>& bimodal_table){
        uint32_t i = index / 64;
        uint16_t offset = index % 64;
        uint64_t mask = (uint64_t(1) << offset);
        return (bimodal_table[i] & mask) >> offset;
    }

    template <uint64_t size>
    void set_bimodal_bit(uint32_t index, uint8_t bit, std::array<uint64_t,size>& bimodal_table){
        uint32_t i = index / 64;
        uint16_t offset = index % 64;
        //printf("%d %d\n", bit, offset);
        //std::cout << std::bitset<64>(bimodal_table[i]) << std::endl;
        
        uint64_t mask = ~( uint64_t(1) << offset);
        uint64_t bit_mask = (uint64_t(bit) << offset);
        
        //std::cout << std::bitset<64>(bimodal_table[i]) << std::endl;
        bimodal_table[i] &= mask;
        bimodal_table[i] |= bit_mask;
        //std::cout << std::bitset<64>(bimodal_table[i]) << std::endl;
        //sleep(2);
    }

    std::pair<uint32_t, uint32_t> get_bimodal_index(uint64_t pc){
        
        uint64_t combined = pc ^ (pc >> 2) ^ (pc >> 5);
        
        uint64_t mask1 = (1 << BIMODAL_PREDICTION_BITS) - 1;
        uint64_t mask2 = ((1 << BIMODAL_HYSTERESIS_BITS) - 1);

        uint32_t prediction_index = mask1 & combined;
        uint32_t hysteresis_index = mask2 & (combined >> (BIMODAL_PREDICTION_BITS - BIMODAL_HYSTERESIS_BITS));
        //printf("Indices %d %d\n",prediction_index, hysteresis_index);
        //printf("GOLD STANDARD %d %d\n", prediction_index, hysteresis_index);
        return {prediction_index, hysteresis_index};
    }

    uint8_t access_bimodal_entry(uint64_t pc){
        uint32_t prediction_index = get_bimodal_index(pc).first;
        return get_bimodal_bit(prediction_index, bimodal_prediction_bits);
    }



// **********************************************************
// Functions for the tagged tables

    template<const table_parameters& params>
    std::optional<tagged_entry> tagged_table<params>::access_entry(uint64_t pc){
        uint64_t index = get_index(pc);
        uint64_t tag = compute_tag(pc);
        
        tagged_entry t = entries[index];
        
        if(t.tag == tag){
            return std::optional<tagged_entry>{t};
        }
        return std::optional<tagged_entry>{};
    }

    template<const table_parameters& params>
    tagged_entry tagged_table<params>::get_entry(uint32_t index){
        return entries[index];
    }

    template<const table_parameters& params>
    void tagged_table<params>::set_entry(uint32_t index, tagged_entry t){
        entries[index] = t;
    }

    template<const table_parameters& params>
    void tagged_table<params>::allocate_entry(uint64_t pc, bool taken){
        int index = get_index(pc);
        tagged_entry t;
        t.tag = compute_tag(pc);
        t.useful_counter = 0;
        if(taken){
            t.counter = WEAK_TAKEN;
        }else{
            t.counter = WEAK_NOT_TAKEN;
        }
        set_entry(index, t);
    }


    // Shift registers
    template<const table_parameters& params>
    void tagged_table<params>::update_history(std::bitset<GLOBAL_SIZE>& global, std::bitset<PATH_HISTORY_SIZE>& path) {
            // Global history
            uint64_t size = params.index_size + params.tag_size;
            bool last_bit = folded_history.test(size-1);
            folded_history <<= 1;
            folded_history.set(0, global.test(0) ^ last_bit);
            
            uint8_t i = params.history_length % size;
            folded_history.set(i, global.test(params.history_length) ^ folded_history.test(i));

            // Path history, could probably just merge this with the global history actually but path history must be 16 bits
            /*last_bit = folded_path_history.test(params.index_size-1);
            folded_path_history <<= 1;
            i = PATH_HISTORY_SIZE % params.index_size;
            folded_path_history.set(0, last_bit ^ path.test(0));
            folded_path_history.set(i, path.test(PATH_HISTORY_SIZE-1));

            // Not sure the best way to change this up so the tag is different enough
            last_bit = folded_tag.test(params.tag_size-1);
            folded_tag <<= 1;
            folded_tag.set(0, global.test(0) ^ last_bit);
            i = (params.history_length-3) % params.tag_size;
            folded_tag.set(i, global.test(params.history_length-3) ^ folded_tag.test(i));*/
    }

    template<const table_parameters& params>
    int tagged_table<params>::get_index(uint64_t pc){
        
        //uint64_t folded_pc = (pc & mask) ^ ((pc >> (params.index_size)) & mask);
        //uint64_t index = folded_history.to_ulong() ^ folded_path_history.to_ulong() ^ folded_pc;
        uint64_t combined = pc ^ (pc >> 2) ^ (pc >> 5) ^ folded_history.to_ulong();
        uint64_t mask = (uint64_t(1) << params.index_size)-1;
    
        return combined & mask;
    }

    template<const table_parameters& params>
    uint16_t tagged_table<params>::compute_tag(uint64_t pc){
        //uint16_t tag = (pc & mask) ^ (pc >> (5 + params.tag_size) & mask) ^ folded_tag.to_ulong();
        uint64_t combined = (pc ^ (pc >> 2) ^ (pc >> 5)) ^ folded_history.to_ulong();
        uint64_t mask = ((uint64_t(1) << params.tag_size)-1);
        uint16_t tag = (pc & mask) ^ (combined >> params.index_size) & mask;
        return tag;
    }

};

#endif