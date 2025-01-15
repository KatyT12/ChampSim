import Assert::*;
import LFSR::*;
import Assert::*;
import StmtFSM::*;
import Vector::*;
import RegFile::*;
import FIFO::*;

import TageTest::*;
import BrPred::*;
import BranchParams::*;
import Tage::*;


`define REGFILE_INIT "Build/regfileMemInit"

(* synthesize *)
module mkRegTestBench(Empty);

  module mkLFIFO1 (FIFO#(t)) provisos(Bits#(t, _a));
      Reg#(t) data <- mkRegU();
      Reg#(Bool) full <- mkReg(False);
      RWire#(void) deqEN <- mkRWire();
      Bool deqp = isValid (deqEN.wget());
      
      method Action enq(t x) if
        (!full || deqp);
        full <= True; data <= x;
      endmethod
      
      method Action deq() if (full);
      full <= False; deqEN.wset(?);
      endmethod
      method t first() if (full);
      return (data);
      endmethod
      method Action clear();
      full <= False;
      endmethod
    endmodule

  RegFile#(Bit#(5), Bit#(5)) rf <- mkRegFileWCF(0, maxBound);
  
  Reg#(Vector#(7, Bool)) allocs <- mkReg(replicate(False));
  Tage#(7) tage <- mkTage;
  FIFO#(UInt#(4)) m <- mkLFIFO1;

    Stmt stmt = seq
      action 
        let entry0 = tage.debugGetEntry(123, 0);
        let entry1 = tage.debugGetEntry(123, 1);
        let entry2 = tage.debugGetEntry(123, 2);
        let entry3 = tage.debugGetEntry(123, 3);
        let entry4 = tage.debugGetEntry(123, 4);
        let entry5 = tage.debugGetEntry(123, 5);
        let entry6 = tage.debugGetEntry(123, 6);

        $display(fshow(entry0)); // 9
        $display(fshow(entry1)); //
        $display(fshow(entry2));
        $display(fshow(entry3));
        $display(fshow(entry4));
        $display(fshow(entry5));
        $display(fshow(entry6)); // 12

        
        
    endaction

    m.enq(3);
    let a <- m.deq;
    m.enq(2);


      //$display(fshow(rf.sub(0)));
        //$display(fshow(rf.sub(1)));
 
    endseq;

  mkAutoFSM(stmt);
endmodule