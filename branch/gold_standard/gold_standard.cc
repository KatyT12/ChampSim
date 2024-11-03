#include "./Predictors/Bimodal/Model/Bimodal.hpp"
#include "include/gold_standard.hpp"
#include "include/types.h"
#include "include/bsv_predictor.hpp"
#include "ooo_cpu.h"

namespace {
  bsv_predictor bluespec_predictor;

  #ifndef MODEL_OFF
  gold_standard::gold_standard_predictor model_predictor;
  #endif
  uint64_t prediction_count = 0;

  bool last_model_prediction;
  bool last_bsv_prediction;
}

void O3_CPU::initialize_branch_predictor() {
  //gold_standard_predictor model(); 
  bluespec_predictor.initialise();
  #ifndef MODEL_OFF
  model_predictor.initialise();
  #endif
}

uint8_t O3_CPU::predict_branch(uint64_t ip)
{
  uint8_t bsv_prediction = bluespec_predictor.predict_branch(ip);
  #ifndef MODEL_OFF
  uint8_t model_prediction = model_predictor.predict_branch(ip);
  last_model_prediction = model_prediction > 0;
  last_bsv_prediction = bsv_prediction > 0;
  #endif
  return bsv_prediction;
}


void O3_CPU::last_branch_result(uint64_t ip, uint64_t branch_target, uint8_t taken, uint8_t branch_type)
{
    // Bascially does nothing 
    
    if(branch_type == BRANCH_CONDITIONAL){
      //sleep(1);
      bluespec_predictor.last_branch_result(ip, branch_target, taken, branch_type);
      #ifndef MODEL_OFF
      model_predictor.last_branch_result(ip, branch_target, taken, branch_type);
      prediction_count++;
      
      #ifdef DEBUG_DATA
        DebugData& bsv_debug = bluespec_predictor.last_debug_entry;
        DebugData& model_debug = model_predictor.last_debug_entry;
        assert_message(bsv_debug == model_debug, "Debug data has diverged on %ld after %ld predicts\nGold standard: %ld %ld %ld\nBluespec predictor: %ld %ld %ld\n", ip, prediction_count, model_debug.entryNumber, model_debug.entryValues, (uint64_t)model_debug.global_history, bsv_debug.entryNumber, bsv_debug.entryValues, (uint64_t)bsv_debug.global_history);
      #endif
      assert_message(last_bsv_prediction == last_model_prediction, "Failed on %ld after %ld instructions\n gold standard predicts: %d, bsv predictor predicts: %d\n", ip, prediction_count, last_model_prediction, last_bsv_prediction);
      #endif
    }
    //bluespec_predictor.last_branch_result(ip, branch_target, taken, branch_type);
}
