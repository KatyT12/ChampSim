import GlobalBranchHistory::*;
import FoldedHistory::*;
import BrPred::*;
import BranchParams::*;
import TaggedTable::*;
import Tage::*;

import LFSR::*;
import Assert::*;
import StmtFSM::*;
import Vector::*;

typedef 10 FoldingSize;


(* synthesize *)
module mkTempTestBench(Empty);
    Tage#(7) tage <- mkTage;
    Reg#(Int#(64)) count  <- mkReg(0);
    
    Stmt stmt = seq     
        count <= count + 1;
        //tage.debugTables(43);
        tage.dirPredInterface.nextPc(13);
        //action let a <- tage.dirPredInterface.pred[0].pred; endaction

        
        tage.debugAllocate(13,2);
        tage.debugAllocate(13,5);
        tage.debugAllocate(13,6);
        action 
        let a <- tage.dirPredInterface.pred[0].pred;
        endaction
        $display("--%d--\n", count);
    endseq;

  mkAutoFSM(stmt);
endmodule