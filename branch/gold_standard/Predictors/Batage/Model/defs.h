#include <utility>
#include <inttypes.h>

namespace gold_standard {
    
    #define GLOBAL_SIZE 256
    #define PATH_HISTORY_SIZE 16
    #define TAGE_TAKEN_CTR_INIT 0
    #define TAGE_NOTTAKEN_CTR_INIT 0


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
        uint32_t pred_table = 0;
        
        tagged_entry provider_entry;
        uint8_t provider_confidence;
        uint8_t alt_confidence;


        bool taken = false;
        bool provider_prediction = false;
        bool alt_prediction = false;
    } trainingInfo;

    #define DEFAULT_VALUE tagged_entry{0,TAGE_TAKEN_CTR_INIT, TAGE_NOTTAKEN_CTR_INIT}

    void update_dual(uint8_t& counter1, uint8_t& counter2, bool taken, uint8_t limit){
        if(taken && counter1 <= limit){
            counter1 = std::min(limit, uint8_t(counter1+1));
        }else if(!taken && counter2 <= limit) {
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
}
