import GlobalBranchHistory::*;
import FoldedHistory::*;
import BrPred::*;
import BranchParams::*;
import TaggedTable::*;
import Tage::*;
import Assert::*;

import LFSR::*;
import Assert::*;
import StmtFSM::*;
import Vector::*;

typedef 10 FoldingSize;

`define NUM_TABLES 7

(* synthesize *)
module mkTempTestBench(Empty);
  Tage#(`NUM_TABLES) tage <- mkTage;
  
  // testcase for testAltPred
  Reg#(Vector#(`NUM_TABLES, Bool)) allocs <- mkReg(replicate(False));
  Reg#(Tuple2#(Bit#(3), Bit#(3))) expected <- mkReg(tuple2(0,0));
  Reg#(Addr) pc <- mkRegU;
  
  Reg#(UInt#(3)) i <- mkRegU;
    
  Stmt testPredAltpred = (seq
    for(i <= 0; i < `NUM_TABLES; i <= i+1) action 
        if(allocs[i]) begin
          tage.debugAllocate(pc,pack(i));
        end
        else
          tage.debugResetEntry(pc,pack(i));

    endaction 
    
    action
      match {.e1, .e2} = tage.debugPredAltpred;
      Tuple2#(Bit#(3), Bit#(3)) values = tuple2(-1,-1);
      if (e1 matches tagged Valid {.ind, .entry})
        if (e2 matches tagged Valid {.ind2, .entry2})
          values = tuple2(ind, ind2);
        else
        values = tuple2(ind, -1);
      $display(fshow(values));
      dynamicAssert(values == expected, "Failed AltPred test case\n");
    endaction
    
  endseq);
  FSM testPredAltpredFSM <- mkFSM(testPredAltpred);

    
    Reg#(Int#(64)) count  <- mkReg(0);
    
    Stmt stmt = seq     
        count <= count + 1;
        //tage.debugTables(43);
        tage.dirPredInterface.nextPc(13);
        //action let a <- tage.dirPredInterface.pred[0].pred; endaction

        allocs <= cons(False, cons(False, cons(True, cons(False, cons(False, cons(True, cons(True, nil)))))));
        pc <= 13;
        expected <= tuple2(6, 5);
        
        testPredAltpredFSM.start;
        testPredAltpredFSM.waitTillDone;

        // (4, 1)
        allocs <= cons(False, cons(True, cons(False, cons(False, cons(True, cons(False, cons(False, nil)))))));
        pc <= 13;
        expected <= tuple2(4, 1);
        testPredAltpredFSM.start;
        testPredAltpredFSM.waitTillDone;
      
        /*tage.debugAllocate(13,2);
        tage.debugAllocate(13,5);
        tage.debugAllocate(13,6);
        action 
        let a <- tage.dirPredInterface.pred[0].pred;
        endaction
        $display("--%d--\n", count);*/
    endseq;

  mkAutoFSM(stmt);
endmodule