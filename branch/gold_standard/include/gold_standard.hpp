#define DEBUG_DATA
#include<stdio.h>
#include<instruction.h>
#include<bitset>

#ifndef GOLDSTANDARD_HPP
#define GOLDSTANDARD_HPP

#ifndef SCRIPT_LOCATION
#define SCRIPT_LOCATION "./branch/gold_standard/script.sh"
#endif

#ifndef DEBUG
#define DEBUG 0
#endif

#define debug_printf(fmt, ...) \
  do { if(DEBUG) { \
    printf(fmt, __VA_ARGS__); \
    }}\
  while(0);

#define assert_message(expr, fmt, ...) \
  if(!(expr)) {\
    printf(fmt, __VA_ARGS__); \
    assert(expr); \
  }

struct DebugData_ {
  uint64_t entryNumber;
  uint64_t entryValues;
  __uint128_t global_history;

  bool operator==(const DebugData_& d) const {
    return (entryNumber == d.entryNumber && entryValues == d.entryValues && global_history == d.global_history);
  }
};
typedef struct DebugData_ DebugData;

class predictor_concept {
  public:  
      virtual ~predictor_concept() = default;
      virtual void initialise() = 0;
      virtual void last_branch_result(uint64_t ip, uint64_t target, uint8_t taken, uint8_t branch_type) = 0;
      virtual uint8_t predict_branch(uint64_t ip) = 0; 
};

namespace gold_standard {
  class gold_standard_predictor : predictor_concept {
  private:
    void impl_initialise();
    void impl_last_branch_result(uint64_t ip, uint64_t target, uint8_t taken, uint8_t branch_type);
  
  #ifdef DEBUG_DATA
    std::pair<uint8_t, DebugData> impl_predict_branch(uint64_t ip); 
  #else
    uint8_t impl_predict_branch(uint64_t ip); 
  #endif

  public:
    DebugData last_debug_entry;
    void initialise(){
      impl_initialise();
    }
    void last_branch_result(uint64_t ip, uint64_t target, uint8_t taken, uint8_t branch_type){
      if(branch_type == BRANCH_CONDITIONAL){
        impl_last_branch_result(ip, target, taken, branch_type);
      }
    }
    
    #ifdef DEBUG_DATA
    uint8_t predict_branch(uint64_t ip){
      auto resp = impl_predict_branch(ip);
      last_debug_entry = resp.second;
      return resp.first;
    }; 
    #else
    uint8_t predict_branch(uint64_t ip){
      return impl_predict_branch(ip);
    }
    #endif

  };
}

#endif
