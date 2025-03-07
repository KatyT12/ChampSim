#ifndef BIMODAL_PREDICTOR_HPP
#define BIMODAL_PREDICTOR_HPP

#include "../../../include/gold_standard.hpp"
#include <unistd.h>

#define PC_SZ 12
#define ENTRIES 1 << PC_SZ

namespace gold_standard {
    // Default values of 0
    std::array<uint8_t,ENTRIES> table;    
    void gold_standard_predictor::impl_initialise(){
        table.fill(2);
    }

    // Luckily updates are immediately after the predictions
    void gold_standard_predictor::impl_last_branch_result(uint64_t ip, uint64_t target, uint8_t taken, uint8_t branch_type){
        uint16_t index = (ip >> 2) & 0xFFF;
        uint8_t entry = table[index];
        
        //printf("gold index: %d ip:%ld %d\n", index,  ip, entry);
        if(taken) entry = std::min(entry +1,3);
        else entry = std::max(entry-1, 0);
        table[index] = entry;
    }

    #ifdef DEBUG_DATA
        std::pair<uint8_t,DebugData> gold_standard_predictor::impl_predict_branch(uint64_t ip){
            uint16_t index = (ip >> 2) & 0xFFF;
            uint8_t entry = table[index];
            DebugData debug{index, entry, 0};
            return {entry > 1, debug};    
        }
    #else
        uint8_t gold_standard_predictor::impl_predict_branch(uint64_t ip){
            uint16_t index = (ip >> 2) & 0xFFF;
            uint8_t entry = table[index];
            
            return entry > 1;    
        }
    #endif

};

#endif