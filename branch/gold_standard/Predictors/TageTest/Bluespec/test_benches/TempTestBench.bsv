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
    Tage tage <- mkTage;
    Reg#(Int#(64)) count  <- mkReg(0);
    
    Stmt stmt = seq     
        count <= count + 1;
        tage.debugTables(43);
        $display("--%d--\n", count);
    endseq;

  mkAutoFSM(stmt);
endmodule