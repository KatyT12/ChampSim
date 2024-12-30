import Assert::*;
import LFSR::*;
import Assert::*;
import StmtFSM::*;
import Vector::*;
import RegFile::*;

import TageTest::*;
import BrPred::*;
import BranchParams::*;
import Tage::*;


`define REGFILE_INIT "Build/regfileMemInit"

(* synthesize *)
module mkRegTestBench(Empty);

  RegFile#(Bit#(3), Bit#(5)) rf <- mkRegFileWCFLoad(regInitFilename, 0, maxBound);
  
  Reg#(Vector#(7, Bool)) allocs <- mkReg(replicate(False));
  Tage#(7) tage <- mkTage;

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


      //$display(fshow(rf.sub(0)));
        //$display(fshow(rf.sub(1)));
 
    endseq;

  mkAutoFSM(stmt);
endmodule