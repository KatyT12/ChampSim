import BimodalTable::*;
import BranchParams::*;
import Assert::*;
import StmtFSM::*;
import Vector::*;

typedef 10 FoldingSize;
(* synthesize *)
module mkBimodalTestBench(Empty);
    Reg#(Bool) starting <- mkReg(True);
    Reg#(UInt#(10)) count <- mkReg(0);

    BimodalTable#(13, 11) bimodalTable <- mkBimodalTable;
    
    Stmt stmt = seq     
        // Test indices
        $display(fshow(bimodalTable.trainingInfo(11)));
        $display(fshow(bimodalTable.trainingInfo(12)));
        $display(fshow(bimodalTable.trainingInfo(13)));
        $display(fshow(bimodalTable.trainingInfo(102)));
        $display(fshow(bimodalTable.trainingInfo(12438)));
        $display(fshow(bimodalTable.trainingInfo(3478)));
    endseq;
  mkAutoFSM(stmt);
endmodule