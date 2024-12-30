#include "../../../include/gold_standard.hpp"
#include "../../../include/Components/lfsr.hpp"
#include <memory>
#include <iostream>
#include <optional>
#include <utility>
#include <algorithm>

namespace gold_standard {

    #define GLOBAL_SIZE 256
    #define PATH_HISTORY_SIZE 16
    #define TAGE_PRED_CTR_INIT 0

    

    typedef struct {
        uint32_t tag;
        uint8_t useful_counter;
        uint8_t counter;
    } tagged_entry;

    typedef struct {
        uint16_t index_size;
        uint16_t tag_size;
        uint16_t history_length;
    } table_parameters;

    class table{
        public:
            virtual void print_size() = 0;
            virtual void update_history(std::bitset<GLOBAL_SIZE>& global, std::bitset<PATH_HISTORY_SIZE>& path) = 0;
            
            virtual int get_index(uint64_t pc) = 0;
            virtual uint16_t compute_tag(uint64_t pc) = 0;

            virtual std::optional<tagged_entry> access_entry(uint64_t pc) = 0;
            virtual tagged_entry get_entry(uint32_t index) = 0;
            virtual void allocate_entry(uint64_t pc, bool taken) = 0;
            virtual void set_entry(uint32_t index, tagged_entry t) = 0;
            ~table() = default;
    };

    template <const table_parameters& params>
    class tagged_table : public table {
        public:
            static constexpr uint64_t num_entries = ( 1 << params.index_size);
            std::array<tagged_entry, num_entries> entries;
            uint16_t history_length;
            uint8_t tag_size;
            
            
            std::bitset<params.index_size+params.tag_size> folded_history;
            std::bitset<params.index_size> folded_path_history;
            std::bitset<params.tag_size> folded_tag; // History for the tag
            
            tagged_table(){
                entries.fill(tagged_entry{0,0,TAGE_PRED_CTR_INIT});
                folded_history.reset();
                folded_path_history.reset();
                folded_tag.reset();
            }
            
            int get_index(uint64_t pc);
            uint16_t compute_tag(uint64_t pc);

            std::optional<tagged_entry> access_entry(uint64_t pc);
            tagged_entry get_entry(uint32_t index);
            void allocate_entry(uint64_t pc, bool taken);
            void set_entry(uint32_t index, tagged_entry t);
            
            void update_history(std::bitset<GLOBAL_SIZE>& global, std::bitset<PATH_HISTORY_SIZE>& path);

            void print_size() override {
                printf("%ld\n", entries.size());
            }
    };

    using tagged_tables_type = std::vector<std::unique_ptr<table>>;

    typedef struct {
        public:
        bool use_bimodal = false;
        bool alt_bimodal = false;
        
        // Indices used
        uint32_t alt_table = 0;
        uint32_t pred_table = 0;
        bool taken = false;
        bool provider_prediction = false;
        bool alt_prediction = false;
    } trainingInfo;


    uint8_t access_bimodal_entry(uint64_t pc);
    std::pair<uint32_t, uint32_t> get_bimodal_index(uint64_t pc);
    
    template <uint64_t size>
    uint8_t get_bimodal_bit(uint32_t index, std::array<uint64_t, size>& bimodal_table);
    template <uint64_t size>
    void set_bimodal_bit(uint32_t index, uint8_t bit, std::array<uint64_t, size>& bimodal_table);

    void update_counter(uint8_t& counter, bool increment, uint8_t limit){
        if(increment){
            counter = std::min(limit, uint8_t(counter+1));
        }else{
            counter = std::max(0, counter-1);
        }
    }

    void print_training_data(trainingInfo t){
        printf("Use Bimodal: %d Alt Bimodal: %d\n", t.use_bimodal, t.alt_bimodal);
        printf("Taken: %d Provider: %d Alt: %d\n", t.taken, t.provider_prediction, t.alt_prediction);
        printf("Provider table: %d Alt table: %d\n", t.pred_table, t.alt_table);
    }
}
