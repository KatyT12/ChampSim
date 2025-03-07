import GlobalBranchHistory::*;
import FoldedHistory::*;
import BrPred::*;
import BranchParams::*;
import TaggedTable::*;
import Tage::*;
import Util::*;

import Assert::*;
import LFSR::*;
import Assert::*;
import StmtFSM::*;
import Vector::*;
import RegFile::*;

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


  /// For allocation testing
  Reg#(Bit#(`NUM_TABLES)) replaceAble <- mkRegU;
  Reg#(Bit#(`NUM_TABLES)) expectedIn <- mkRegU;
  Reg#(Bit#(3)) startFrom <- mkRegU;
  Reg#(Bool) useBimodal <- mkReg(False);
  
    
  Stmt testPredAltpred = (seq
    for(i <= 0; i < `NUM_TABLES; i <= i+1) action 
        if(allocs[i]) begin
          tage.debugAllocate(pc,pack(i));
        end
        else
          tage.debugResetEntry(pc,pack(i));
          $display("RESET %d\n", i);
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
  
  Stmt testPredictionResult = (seq
    action
      let ti <- tage.dirPredInterface.pred[0].pred;
      $display(ti.taken);
    endaction
    
  endseq);

  Stmt testAllocation = (seq
    action
      TageTrainInfo#(`NUM_TABLES) tst = unpack(0);
      if(!useBimodal)
        tst.provider_info = tagged Valid ProviderTrainInfo{provider_table: startFrom, index: 5, provider_entry: TaggedTableEntry{tag: 1, predictionCounter:0, usefulCounter:0}};
      else
        tst.provider_info = tagged Invalid;
      tst.pc = 13;
      tst.replaceableEntries = truncate(reverseBits(replaceAble));
      let result <- tage.debugMispredictAllocation(tst, False);
      
      let start = useBimodal ? 0 : startFrom;
      $display("INDEX CHOSEN from %d ",start, fshow(result), "\n");
      if (result matches tagged Valid .i)
        dynamicAssert(unpack(reverseBits(expectedIn)[i]), "testAllocation: Invalid index chosen");
      else
        dynamicAssert(reverseBits(expectedIn) == 0, "testAllocation: Missing index for valid allocation");
      
    endaction
    useBimodal <= False;
    
  endseq);
  
  
  
  FSM testPredictionResultFSM <- mkFSM(testPredictionResult);
  FSM testPredAltpredFSM <- mkFSM(testPredAltpred);
  FSM testAllocationFSM <- mkFSM(testAllocation);


    Stmt stmt = seq
        // -------------- Exhaustively Test utility functions
        dynamicAssert(boundedUpdate(2'b11, True) == 2'b11,"");
        dynamicAssert(boundedUpdate(2'b00, False) == 2'b00, "");
        dynamicAssert(boundedUpdate(2'b00, False) == 2'b00, "");
        
        dynamicAssert(weakCounter(3'b100), "");
        dynamicAssert(weakCounter(3'b011), "");
        dynamicAssert(!weakCounter(3'b101), "");
        dynamicAssert(!weakCounter(3'b111), "");
        dynamicAssert(!weakCounter(3'b001), "");
        dynamicAssert(!weakCounter(3'b000), "");

        dynamicAssert(takenFromCounter(3'b100), "");
        dynamicAssert(takenFromCounter(3'b101), "");
        dynamicAssert(takenFromCounter(3'b111), "");
        dynamicAssert(!takenFromCounter(3'b001), "");
        dynamicAssert(!takenFromCounter(3'b011), "");
        dynamicAssert(!takenFromCounter(3'b000), "");
        // ------------------

        // Check that entries are initialised to 0
        
        
          
        // TODO: Add randomness here, or exhaustively check
        action
          let entry = tage.debugGetEntry(1293, 4); 
          $display(fshow(entry));
          dynamicAssert((entry.predictionCounter == 0 && entry.usefulCounter == 0 && entry.tag == 0), "Tagged tables need to be initialised to 0");
        endaction

        tage.dirPredInterface.nextPc(4010103);
        
        allocs <= cons(False, cons(False, cons(True, cons(False, cons(False, cons(True, cons(True, nil)))))));
        pc <= 4010103;
        expected <= tuple2(6, 5);
        
        testPredAltpredFSM.start;
        testPredAltpredFSM.waitTillDone;

        // (4, 1)
        allocs <= cons(False, cons(True, cons(False, cons(False, cons(True, cons(False, cons(False, nil)))))));
        pc <= 4010103;
        expected <= tuple2(4, 1);
        testPredAltpredFSM.start;
        testPredAltpredFSM.waitTillDone;

        tage.dirPredInterface.nextPc(13);
      
        // test predictions
        testPredictionResultFSM.start;
        testPredictionResultFSM.waitTillDone;


        // Test allocations

        // 4 or 5
        replaceAble <= 7'b1000110;
        startFrom <= 2;
        expectedIn <= 7'b0000110;

        testAllocationFSM.start;
        testAllocationFSM.waitTillDone;

        // 2 or 3
        replaceAble <= 7'b1110100;
        startFrom <= 2;
        expectedIn <= 7'b0000100;

        testAllocationFSM.start;
        testAllocationFSM.waitTillDone;

        replaceAble <= 7'b1110000;
        startFrom <= 2;
        expectedIn <= 7'b0000000;

        testAllocationFSM.start;
        testAllocationFSM.waitTillDone;

        replaceAble <= 7'b1111111;
        startFrom <= 2;
        expectedIn <= 7'b0001110;
        testAllocationFSM.start;
        testAllocationFSM.waitTillDone;
  

        replaceAble <= 7'b1111111;
        expectedIn <= 7'b1110000;
        useBimodal <= True;
        testAllocationFSM.start;
        testAllocationFSM.waitTillDone;

        replaceAble <= 7'b1111111;
        startFrom <= 6;
        expectedIn <= 7'b0000000;
        testAllocationFSM.start;
        testAllocationFSM.waitTillDone;

        replaceAble <= 7'b0101101;
        startFrom <= 0;
        expectedIn <= 7'b0101100;
        testAllocationFSM.start;
        testAllocationFSM.waitTillDone;
        
    endseq;

  mkAutoFSM(stmt);
endmodule