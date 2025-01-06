import Assert::*;
import LFSR::*;
import Assert::*;
import StmtFSM::*;
import Vector::*;
import RegFile::*;
import FIFO::*;


import BrPred::*;
import BranchParams::*;
import CircBuff::*;

`define REGFILE_INIT "Build/regfileMemInit"

(* synthesize *)
module mkCircTestBench(Empty);

    CircBuff#(8, UInt#(7)) cb <- mkCircBuff;
    Reg#(UInt#(7)) cnt <- mkReg(0);
    Vector#(100, Reg#(CircBuffIndex#(8))) ind <- replicateM(mkRegU);

    rule incCount;
        cnt <= cnt + 1;
    endrule

    Stmt stmt = seq
        
        action
            for(Integer i = 0; i < 2; i = i + 1) begin
                let a <- cb.specAssign[i].specAssign;
                ind[i] <= a;
            end
        endaction
        
        cb.enqueue(1, ind[1]);
        action
            cb.enqueue(0, ind[0]);
            let f <- cb.handleMispred(ind[0]);
        endaction

        action let t <- cb.retrieveNext; endaction
        action let t <- cb.retrieveNext; endaction

        /* Mispredict on last of 4 branches, but recieve last branch first */
        action
            for(Integer i = 0; i < 2; i = i + 1) begin
                let a <- cb.specAssign[i].specAssign;
                ind[i] <= a;
            end
        endaction

        action let a <- cb.specAssign[0].specAssign; ind[2] <= a; endaction

        action cb.enqueue(4, ind[2]); let f <- cb.handleMispred(ind[2]); endaction
        cb.enqueue(2, ind[0]);
        cb.enqueue(3, ind[1]);
        

        action let t <- cb.retrieveNext; endaction
        action let t <- cb.retrieveNext; endaction
        action let t <- cb.retrieveNext; endaction
        action let t <- cb.retrieveNext; endaction

        /* Update at the same time as a mispredict */
        action
            for(Integer i = 0; i < 2; i = i + 1) begin
                let a <- cb.specAssign[i].specAssign;
                ind[i] <= a;
            end
        endaction

        action
            let a <- cb.specAssign[0].specAssign;
            ind[2] <= a;
            cb.enqueue(6, ind[1]);
            let f <- cb.handleMispred(ind[1]);
        endaction

        action let t <- cb.retrieveNext; endaction
        action let t <- cb.retrieveNext; endaction
        cb.enqueue(5, ind[0]);
        action let t <- cb.retrieveNext; endaction
        action let t <- cb.retrieveNext; endaction



    endseq;

  mkAutoFSM(stmt);
endmodule