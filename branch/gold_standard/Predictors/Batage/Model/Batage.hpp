#ifndef BATAGE_HPP
#define BATAGE_HPP

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
#include <string>


#define DEBUG_PRED 0

namespace gold_standard {
    // Default values of 0
    
    #define COUNTER_SIZE 3
    #define COUNTER_MAX ((1 << COUNTER_SIZE) - 1)
    #define BIMODAL_COUNTER_SIZE 3

     // USE HYSTERESIS LATER
    constexpr uint8_t bimodal_table_init (1 << (BIMODAL_COUNTER_SIZE-1));

    // Index size, Tag size, History length
    std::bitset<GLOBAL_SIZE> global_history;
    std::bitset<PATH_HISTORY_SIZE> path_history;

    std::array<uint8_t, BIMODAL_TABLE_NUM_ENTRIES> bimodal_table;
    
    tagged_tables_type tagged_tables;
    trainingInfo last_training_data;
    uint8_t cat;
    lfsr<LFSR_SIZE> feedback_shift_register(0x1A2B3C4D5E6F7D8E, 0x8000000000000001);

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
    std::string last = "";

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
        
        bimodal_table.fill(bimodal_table_init);
        cat = 0;

        std::cout << "Initialized\n";
    }

    uint8_t gold_standard_predictor::impl_predict_branch(uint64_t ip){
        
        bool found_provider = false;
        last = "";
        bool found_alt = false;
        int provider = 0;
        int  alt = 0;
        uint32_t alt_index = 0;
        tagged_entry provider_entry;
        tagged_entry alt_entry;
        
        std::vector<uint8_t> upper_entries;
        std::array<uint32_t, NUM_TAGGED_TABLES> indices;
        indices.fill(0);

        //printf("GOLD STANDARD PREDICT %d, LSFSR %d", ip)
        uint8_t conf = 3;
        uint8_t alt_conf = 0;
        
        for(int i = tagged_tables.size()-1; i >= 0; i--){
            auto entry = tagged_tables[i]->access_entry(ip);
            uint32_t index = tagged_tables[i]->get_index(ip);
            indices[i] = index;
            if(DEBUG_PRED){
                last += "(" + std::to_string(index) + ", " + std::to_string(entry.has_value()) + "), ";
            }
            if(entry.has_value()){
                tagged_entry ent = entry.value();
                uint8_t confidence = get_tagged_confidence(ent.takenCounter, ent.notTakenCounter);
                
                if(confidence < conf){
                    found_provider = true;
                    found_alt = false;
                    conf = confidence;
                    provider = i;
                    provider_entry = ent;
                }    
                else if(!found_alt){
                    found_alt = true;
                    alt_index = index;
                    alt_conf = confidence;
                    alt = i;
                    alt_entry = ent;
                }
            }
        }
        if(DEBUG_PRED){
            last += "\n";
        }

        for(int i = tagged_tables.size()-1; i >= 0; i--){
            auto entry = tagged_tables[i]->access_entry(ip);
            if(i > provider && entry.has_value()){
                upper_entries.push_back(i);
            }
        }
            debug_printf("%ld\n", ip);
        
        if(found_provider){
            debug_printf("%d\n", provider_entry.takenCounter);
        }

        uint32_t bimodal_index = get_bimodal_index(ip);
        uint8_t bimodal_counter = get_bimodal_counter(bimodal_index, bimodal_table);
        bool bimodal_prediction = bimodal_counter >= (1 << (BIMODAL_COUNTER_SIZE-1));

        last_training_data.upper_entries = upper_entries;
        last_training_data.indices = indices;

        // Set up training data, half of it is not really necessary
        if(!found_provider){
            last_training_data.use_bimodal = true;
            last_training_data.provider_prediction = bimodal_prediction;
            //printf("GOLD STANDARD INDEX %d %d\n", get_bimodal_index(ip).first, get_bimodal_index(ip).second);
            last_training_data.taken = last_training_data.provider_prediction;
        }else{
            if(DEBUG_PRED)
                fprintf(file,"GOLD STANDARD INDEX %ld %d %d %d\n", ip, provider, tagged_tables[provider]->get_index(ip), tagged_tables[provider]->compute_tag(ip));

            last_training_data.use_bimodal = false;
            last_training_data.pred_table = provider;
            last_training_data.provider_prediction = provider_entry.takenCounter > provider_entry.notTakenCounter;
            last_training_data.taken = last_training_data.provider_prediction;
            last_training_data.provider_confidence = conf;
            last_training_data.provider_entry = provider_entry;

            if(!found_alt){
               last_training_data.alt_bimodal = true;
               last_training_data.alt_prediction = bimodal_prediction;
               last_training_data.alt_confidence = get_bimodal_table_confidence(bimodal_counter);
            }else{
                last_training_data.alt_bimodal = false;
                last_training_data.alt_table = alt;
                last_training_data.alt_index = alt_index;
                last_training_data.alt_confidence = alt_conf;
                last_training_data.alt_prediction = alt_entry.takenCounter > alt_entry.notTakenCounter;
                last_training_data.alt_entry = alt_entry;
                // Is this also true if the alternative is bimodal?
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
            fprintf(file, "GOLD STANDARD PRED %llu %s\n", ip, feedback_shift_register.get().to_string().c_str());
            
            fprintf(file, "GOLD STANDARD HISTORY %s\n", global_history.to_string().substr(245,10).c_str());
            fprintf(file, last.c_str());
            fprintf(file, "GOLD STANDARD PREDICTS %d, Actual: %d\n", last_training_data.taken, taken);
        }
        
        bool branch_taken = taken > 0;
        bool mispred = last_training_data.taken != branch_taken;

        uint32_t bimodal_index = get_bimodal_index(ip);
        uint8_t bimodal_counter = get_bimodal_counter(bimodal_index, bimodal_table);

        // ******** Allocation on misprediction
        if(mispred && (last_training_data.use_bimodal || (last_training_data.pred_table < tagged_tables.size()-1))){
            // On a prediction this could be brought along rather than recalculated?
            

            // Decide to allocate or not
            uint16_t random = std::min((long unsigned int)MINAP, ((feedback_shift_register.get().to_ulong() & (LFSR_ALLOCATE_MASK)) >> LFSR_ALLOCATE_SHIFT));
            if(DEBUG_PRED)
                fprintf(file, "GOLD STANDARD ALLOCATE RANDOM: %d, cat: %d\n", random, cat);

            if(random >= ((cat*MINAP)/(CATMAX+1))){
                int8_t replace_tab = -1;
                // Check if there exists an entry with u = 0
                int start = last_training_data.use_bimodal ? 0 : last_training_data.pred_table+1;
                // Small random offset, want to weight this towards 0
                uint8_t offset_rand = ((feedback_shift_register.get().to_ulong() & (LFSR_OFFSET_MASK)) >> LFSR_OFFSET_SHIFT);
                uint8_t offset = 0;
                if(offset_rand > 3 && offset_rand <= 6) offset = 1;
                else if (offset_rand == 7) offset = 2;

                uint8_t mhc = 0;
                uint16_t decay = feedback_shift_register.get().to_ulong() & (LFSR_DECAY_MASK);
                
                if(DEBUG_PRED){
                    std::bitset<14> d(decay);
                    fprintf(file, "GOLD STANDARD ALLOCATE decay: %s, offset: %d\n", d.to_string().c_str(), offset);
                }

                for(uint32_t i = start+offset; i < tagged_tables.size() && replace_tab == -1; i++){
                    int t_index = tagged_tables[i]->get_index(ip);
                    auto entry = tagged_tables[i]->access_entry(ip);
                    if(!entry.has_value()){ // Not upper entry
                        tagged_entry e = tagged_tables[i]->get_entry(t_index);
                        if(get_tagged_confidence(e.takenCounter, e.notTakenCounter) != 0){
                            replace_tab = i;
                        }else{
                            // Decay with some probability
                            fprintf(file, "GOLD STANDARD HIGH CONFIDENCE: %d\n", i);
                            if (is_mhc(e.takenCounter, e.notTakenCounter)) mhc++;
                            if((decay >> (i*2)) & 0x3 >= DECAY_THRESH){ // 1/4 chance of decay independantly
                                if(DEBUG_PRED){
                                    fprintf(file, "GOLD STANDARD ALLOCATE DECAY: %d\n", i);
                                }
                                
                                decay_dual(e.takenCounter, e.notTakenCounter);
                                tagged_tables[i]->set_entry(t_index, e);
                            }
                        }
                        
                    }
                }

                if(replace_tab != -1){
                    int index = tagged_tables[replace_tab]->get_index(ip);
                    if(DEBUG_PRED)
                        fprintf(file, "GOLD STANDARD ALLOCATE: table: %d, index: %d, offset: %d, mhc: %d\n", replace_tab, index, offset, mhc);
                    tagged_tables[replace_tab]->allocate_entry(
                        ip,
                        branch_taken
                    );
                    cat = cat + 1 - 2*mhc;
                    cat = std::min((uint8_t)CATMAX, std::max((uint8_t)0, cat));
                    cat = 0; //Turn of controlled allocation throttling
                }
            }
        }
        

        // ********* Tagged tables update
        //if(!last_training_data.use_bimodal){
            std::unique_ptr<table>& pred = tagged_tables[last_training_data.pred_table];
            std::unique_ptr<table>& alt_table = tagged_tables[last_training_data.alt_table];
            uint16_t pred_index = pred->get_index(ip);
            tagged_entry pred_t = pred->get_entry(pred_index);
            
            if(DEBUG_PRED){
                if(last_training_data.alt_bimodal){
                    fprintf(file, "GOLD STANDARD ALT PRED BIMODAL\n");
                    fprintf(file, "GOLD STANDARD ALT PREDICTION: %d\n", last_training_data.alt_prediction);
                }else if(!last_training_data.use_bimodal){
                    fprintf(file, "GOLD STANDARD ALT PRED TABLE %d\n", last_training_data.alt_table);
                }
                if(!last_training_data.use_bimodal){
                    fprintf(file, "GOLD STANDARD ALT PRED TAKEN %d\n", last_training_data.alt_prediction);
                    fprintf(file, "GOLD STANDARD PROVIDER ENTRY Table: %d Index: %d, Conf: %d, Counters: %d %d\n", last_training_data.pred_table, pred_index, last_training_data.provider_confidence, last_training_data.provider_entry.takenCounter, last_training_data.provider_entry.notTakenCounter);                    
                }else{
                    fprintf(file, "GOLD STANDARD USE BIMODAL\n");
                }
                if(!last_training_data.alt_bimodal && !last_training_data.use_bimodal){
                    fprintf(file, "GOLD STANDARD ALT PREDICTION: %d\n", last_training_data.alt_prediction);
                    fprintf(file, "GOLD STANDARD ALT ENTRY Table: %d Index: %d, Conf: %d, Counters: %d %d\n", last_training_data.alt_table, last_training_data.alt_index, last_training_data.alt_confidence, last_training_data.alt_entry.takenCounter, last_training_data.alt_entry.notTakenCounter);
                }
            }

            // Provider update
            if(last_training_data.use_bimodal){ // Always update Bimodal if provider
                update_counter(bimodal_counter, branch_taken, (1 << BIMODAL_COUNTER_SIZE)-1);
                set_bimodal_counter(bimodal_index, bimodal_counter, bimodal_table);
            }
            else if(last_training_data.alt_prediction != branch_taken || last_training_data.provider_confidence > 0 || last_training_data.alt_confidence > 0){ // If not high confidence
                // LOOK AT: In the text it says if alt mispredicts rather than provider mispredicts, but surely you would want to update if the provider mispredicts
                update_dual(pred_t.takenCounter, pred_t.notTakenCounter, branch_taken, COUNTER_MAX);
                if(DEBUG_PRED){
                    fprintf(file, "GOLD STANDARD DUAL UPDATE 1 %d %d\n", pred_t.takenCounter, pred_t.notTakenCounter);
                }
            }else if(last_training_data.provider_confidence == 0 && last_training_data.alt_confidence == 0 && last_training_data.alt_prediction == branch_taken){
                decay_dual(pred_t.takenCounter, pred_t.notTakenCounter); // If evidence of uselessness
            }

            if(!last_training_data.use_bimodal){
                pred->set_entry(pred_index, pred_t);
            }
            
            // Alt update
            if(!last_training_data.use_bimodal && last_training_data.provider_confidence != 0){
                if(last_training_data.alt_bimodal){ //Bimodal
                    update_counter(bimodal_counter, branch_taken, (1 << BIMODAL_COUNTER_SIZE)-1);
                    set_bimodal_counter(bimodal_index, bimodal_counter, bimodal_table);
                }else{ //Tagged
                    tagged_entry alt = last_training_data.alt_entry;
                    update_dual(alt.takenCounter, alt.notTakenCounter, taken, COUNTER_MAX);
                    alt_table->set_entry(last_training_data.alt_index, alt);
                }
            }

            //Others update
            for(uint8_t i = 0; i < last_training_data.upper_entries.size(); i++){
                uint8_t table_ind = last_training_data.upper_entries[i];
                std::unique_ptr<table>& upper_table = tagged_tables[table_ind];
                uint16_t index = upper_table->get_index(ip);
                tagged_entry t = upper_table->get_entry(index);

                update_dual(t.takenCounter, t.notTakenCounter, taken, COUNTER_MAX);
                upper_table->set_entry(index, t);
                if(DEBUG_PRED){
                    fprintf(file, "GOLD STANDARD UPPER UPDATE Table: %d Index: %d\n", table_ind, index);
                }
            }
        //}

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
    uint8_t get_bimodal_counter(uint32_t index, std::array<uint8_t, size>& bimodal){
        return bimodal[index];
    }

    template <uint64_t size>
    void set_bimodal_counter(uint32_t index, uint8_t counter, std::array<uint8_t, size>& bimodal){
        bimodal[index] = counter;
    }

    uint32_t get_bimodal_index(uint64_t pc){    
        uint64_t combined = pc ^ (pc >> 2) ^ (pc >> 5);
        uint64_t mask = (1 << BIMODAL_TABLE_SIZE) - 1;
        uint32_t prediction_index = mask & combined;
        return prediction_index;
    }

    uint8_t get_bimodal_table_confidence(uint8_t counter){
        if(counter == 3 || counter == 4)
            return 2;
        else if(counter == 2 || counter == 5)
            return 1;
        else
            return 0;
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
        if(taken){
            t.takenCounter = 1;
            t.notTakenCounter = 0;
        }else{
            t.takenCounter = 0;
            t.notTakenCounter = 1;
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
        uint64_t combined = pc ^ (pc >> 2) ^ (pc >> 5) ^ folded_history.to_ulong();
        uint64_t mask = ((uint64_t(1) << params.tag_size)-1);
        uint16_t tag = (pc & mask) ^ ((combined >> params.index_size) & mask);
        return tag;
    }

};

#endif