#include <utility>
#include <inttypes.h>

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

    #define DEFAULT_VALUE tagged_entry{0,0,TAGE_PRED_CTR_INIT}

    std::pair<uint32_t, uint32_t> get_bimodal_index(uint64_t pc);
    uint8_t access_bimodal_entry(uint64_t pc);
    template <uint64_t size>
    uint8_t get_bimodal_bit(uint32_t index, std::array<uint64_t, size>& bimodal_table);
    template <uint64_t size>
    void set_bimodal_bit(uint32_t index, uint8_t bit, std::array<uint64_t, size>& bimodal_table);
}
