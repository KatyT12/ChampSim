#include <utility>
#include <inttypes.h>
#include <array>
#include <vector>

namespace gold_standard {
    
    #define GLOBAL_SIZE 256
    #define PATH_HISTORY_SIZE 16
    #define TAGE_TAKEN_CTR_INIT 0
    #define TAGE_NOTTAKEN_CTR_INIT 0
    #define BIMODAL_COUNTER_SIZE 3
    #define BIMODAL_TABLE_SIZE 12
    #define BIMODAL_TABLE_NUM_ENTRIES (1 << BIMODAL_TABLE_SIZE)
    #define NUM_TAGGED_TABLES 7

    #define LFSR_SIZE 64

    #define LFSR_DECAY_MASK 0x3fff // 14
    #define DECAY_THRESH 2
    
    #define LFSR_OFFSET_MASK 0x1c000
    #define LFSR_OFFSET_SHIFT 14

    #define LFSR_ALLOCATE_MASK 0x00d0000 // 3 bits
    #define LFSR_ALLOCATE_SHIFT 17

    #define MINAP 8
    #define CATMAX 8192
    #define SKIPMAX 2
    

    typedef struct {
        uint32_t tag;
        uint8_t takenCounter;
        uint8_t notTakenCounter;
    } tagged_entry;

    typedef struct {
        public:
        bool use_bimodal = false;
        bool alt_bimodal = false;
        
        // Indices used
        uint32_t alt_table = 0;
        uint32_t alt_index = 0;
        uint32_t pred_table = 0;
        
        tagged_entry provider_entry;
        tagged_entry alt_entry;
        uint8_t provider_confidence;
        uint8_t alt_confidence;

        // Instead form of a bitmask
        std::vector<uint8_t> upper_entries;
        std::array<uint32_t, NUM_TAGGED_TABLES> indices;

        bool taken = false;
        bool provider_prediction = false;
        bool alt_prediction = false;
    } trainingInfo;

    #define DEFAULT_VALUE tagged_entry{0,TAGE_TAKEN_CTR_INIT, TAGE_NOTTAKEN_CTR_INIT}

    void update_dual(uint8_t& counter1, uint8_t& counter2, bool taken, uint8_t limit){
        if(taken && counter1 < limit){
            counter1 = std::min(limit, uint8_t(counter1+1));
        }else if(!taken && counter2 < limit) {
            counter2 = std::min(limit, uint8_t(counter2+1));;
        }
        else{
            if(taken)
                counter2 = std::max(0, counter2-1);
            else
                counter1 = std::max(0, counter1-1);
        }
    }

    void decay_dual(uint8_t& counter1, uint8_t& counter2){
        if(counter1 > counter2){
            counter1 = std::max(0, counter1-1);
        }else{
            counter2 = std::max(0, counter2-1);
        }
    }

    uint8_t get_tagged_confidence(uint8_t takenCounter, uint8_t notTakenCounter){
        uint8_t medium = (takenCounter == (2*notTakenCounter + 1)) || (notTakenCounter == (2*takenCounter + 1));
        uint8_t low = (takenCounter < (2*notTakenCounter + 1)) && (notTakenCounter < (2*takenCounter + 1));
        uint8_t confidence = 2 * low + medium;
        return confidence;
    }

    bool is_mhc(uint8_t takenCounter, uint8_t notTakenCounter){
        double conf =  1.0 + (double)std::min(takenCounter, notTakenCounter)/(2.0+(double)takenCounter+(double)notTakenCounter);
        if(get_tagged_confidence(takenCounter, notTakenCounter) == 0 && conf > 0.17){
            return true;
        }else{
            return false;
        }   
    }

    uint32_t get_bimodal_index(uint64_t pc);
    uint8_t get_bimodal_table_confidence(uint8_t counter);

    template <uint64_t size>
    uint8_t get_bimodal_counter(uint32_t index, std::array<uint8_t, size>& bimodal);

    template <uint64_t size>
    void set_bimodal_counter(uint32_t index, uint8_t counter, std::array<uint8_t, size>& bimodal);
}
