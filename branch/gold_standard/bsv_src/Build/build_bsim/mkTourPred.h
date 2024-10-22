/*
 * Generated by Bluespec Compiler, version 2024.01 (build ae2a2fc6)
 * 
 * On Tue Oct 22 20:31:56 BST 2024
 * 
 */

/* Generation options: keep-fires */
#ifndef __mkTourPred_h__
#define __mkTourPred_h__

#include "bluesim_types.h"
#include "bs_module.h"
#include "bluesim_primitives.h"
#include "bs_vcd.h"
#include "mkTourGHistReg.h"


/* Class declaration for the mkTourPred module */
class MOD_mkTourPred : public Module {
 
 /* Clock handles */
 private:
  tClock __clk_handle_0;
 
 /* Clock gate handles */
 public:
  tUInt8 *clk_gate[0];
 
 /* Instantiation parameters */
 public:
 
 /* Module state */
 public:
  MOD_RegFile<tUInt32,tUInt8> INST_choiceBht;
  MOD_mkTourGHistReg INST_gHistReg;
  MOD_RegFile<tUInt32,tUInt8> INST_globalBht;
  MOD_Reg<tUInt8> INST_globalTakenVec;
  MOD_RegFile<tUInt32,tUInt8> INST_localBht;
  MOD_RegFile<tUInt32,tUInt32> INST_localHistTab;
  MOD_Reg<tUInt64> INST_pc_reg;
  MOD_Reg<tUInt8> INST_predCnt_dummy2_0;
  MOD_Reg<tUInt8> INST_predCnt_dummy2_1;
  MOD_Wire<tUInt8> INST_predCnt_dummy_0_0;
  MOD_Wire<tUInt8> INST_predCnt_dummy_0_1;
  MOD_Wire<tUInt8> INST_predCnt_dummy_1_0;
  MOD_Wire<tUInt8> INST_predCnt_dummy_1_1;
  MOD_Wire<tUInt8> INST_predCnt_lat_0;
  MOD_Wire<tUInt8> INST_predCnt_lat_1;
  MOD_Reg<tUInt8> INST_predCnt_rl;
  MOD_Reg<tUInt8> INST_predRes_dummy2_0;
  MOD_Reg<tUInt8> INST_predRes_dummy2_1;
  MOD_Wire<tUInt8> INST_predRes_dummy_0_0;
  MOD_Wire<tUInt8> INST_predRes_dummy_0_1;
  MOD_Wire<tUInt8> INST_predRes_dummy_1_0;
  MOD_Wire<tUInt8> INST_predRes_dummy_1_1;
  MOD_Wire<tUInt8> INST_predRes_lat_0;
  MOD_Wire<tUInt8> INST_predRes_lat_1;
  MOD_Reg<tUInt8> INST_predRes_rl;
  MOD_Reg<tUInt8> INST_useLocalVec;
 
 /* Constructor */
 public:
  MOD_mkTourPred(tSimStateHdl simHdl, char const *name, Module *parent);
 
 /* Symbol init methods */
 private:
  void init_symbols_0();
 
 /* Reset signal definitions */
 private:
  tUInt8 PORT_RST_N;
 
 /* Port definitions */
 public:
  tUInt8 PORT_EN_nextPc;
  tUInt8 PORT_EN_pred_0_pred;
  tUInt8 PORT_EN_update;
  tUInt8 PORT_EN_flush;
  tUInt64 PORT_nextPc_nextPc;
  tUInt8 PORT_update_taken;
  tUInt64 PORT_update_train;
  tUInt8 PORT_update_mispred;
  tUInt8 PORT_RDY_nextPc;
  tUInt64 PORT_pred_0_pred;
  tUInt8 PORT_RDY_pred_0_pred;
  tUInt8 PORT_RDY_update;
  tUInt8 PORT_RDY_flush;
  tUInt8 PORT_flush_done;
  tUInt8 PORT_RDY_flush_done;
 
 /* Publicly accessible definitions */
 public:
  tUInt8 DEF_WILL_FIRE_flush;
  tUInt8 DEF_WILL_FIRE_update;
  tUInt8 DEF_WILL_FIRE_pred_0_pred;
  tUInt8 DEF_WILL_FIRE_nextPc;
  tUInt8 DEF_WILL_FIRE_RL_canonGlobalHist;
  tUInt8 DEF_CAN_FIRE_RL_canonGlobalHist;
  tUInt8 DEF_WILL_FIRE_RL_predRes_canon;
  tUInt8 DEF_CAN_FIRE_RL_predRes_canon;
  tUInt8 DEF_WILL_FIRE_RL_predCnt_canon;
  tUInt8 DEF_CAN_FIRE_RL_predCnt_canon;
  tUInt8 DEF_CAN_FIRE_flush_done;
  tUInt8 DEF_CAN_FIRE_flush;
  tUInt8 DEF_CAN_FIRE_update;
  tUInt8 DEF_CAN_FIRE_pred_0_pred;
  tUInt8 DEF_CAN_FIRE_nextPc;
 
 /* Local definitions */
 private:
  tUInt8 DEF_predCnt_dummy2_1_read____d21;
  tUInt8 DEF_predCnt_rl__h4503;
  tUInt32 DEF_curGHist__h2774;
  tUInt8 DEF_predRes_rl__h4967;
  tUInt8 DEF_predRes_dummy2_1_read____d19;
  tUInt8 DEF_predRes_lat_0_whas____d13;
  tUInt8 DEF_x_wget__h1888;
  tUInt8 DEF_predCnt_lat_0_whas____d4;
  tUInt8 DEF_x_wget__h852;
  tUInt8 DEF_IF_predRes_lat_0_whas__3_THEN_IF_predRes_lat_0_ETC___d17;
  tUInt8 DEF_upd__h2734;
  tUInt8 DEF_IF_predCnt_lat_0_whas_THEN_IF_predCnt_lat_0_wh_ETC___d8;
  tUInt8 DEF_upd__h1705;
 
 /* Rules */
 public:
  void RL_predCnt_canon();
  void RL_predRes_canon();
  void RL_canonGlobalHist();
 
 /* Methods */
 public:
  tUInt8 METH_flush_done();
  tUInt8 METH_RDY_flush_done();
  void METH_nextPc(tUInt64 ARG_nextPc_nextPc);
  tUInt8 METH_RDY_nextPc();
  tUInt64 METH_pred_0_pred();
  tUInt8 METH_RDY_pred_0_pred();
  void METH_update(tUInt8 ARG_update_taken, tUInt64 ARG_update_train, tUInt8 ARG_update_mispred);
  tUInt8 METH_RDY_update();
  void METH_flush();
  tUInt8 METH_RDY_flush();
 
 /* Reset routines */
 public:
  void reset_RST_N(tUInt8 ARG_rst_in);
 
 /* Static handles to reset routines */
 public:
 
 /* Pointers to reset fns in parent module for asserting output resets */
 private:
 
 /* Functions for the parent module to register its reset fns */
 public:
 
 /* Functions to set the elaborated clock id */
 public:
  void set_clk_0(char const *s);
 
 /* State dumping routine */
 public:
  void dump_state(unsigned int indent);
 
 /* VCD dumping routines */
 public:
  unsigned int dump_VCD_defs(unsigned int levels);
  void dump_VCD(tVCDDumpType dt, unsigned int levels, MOD_mkTourPred &backing);
  void vcd_defs(tVCDDumpType dt, MOD_mkTourPred &backing);
  void vcd_prims(tVCDDumpType dt, MOD_mkTourPred &backing);
  void vcd_submodules(tVCDDumpType dt, unsigned int levels, MOD_mkTourPred &backing);
};

#endif /* ifndef __mkTourPred_h__ */
