#ifndef LFSR_HPP

// Linear feedback shift register implemented in the same way as the BSV library
#define LFSR_HPP
#include <bitset>

template<int size>
class lfsr {
        std::bitset<size> shiftregister;
        std::bitset<size> feed;
    public:
        lfsr(uint64_t seed, uint64_t mask) : shiftregister(seed), feed(mask){}
        
        void next(){
            if(shiftregister[0] == true){
                shiftregister = (shiftregister >> 1) ^ feed;
            }else{
                shiftregister >>= 1;
            }
        }
        
        std::bitset<size> get(){
            return shiftregister;
        }
};
#endif