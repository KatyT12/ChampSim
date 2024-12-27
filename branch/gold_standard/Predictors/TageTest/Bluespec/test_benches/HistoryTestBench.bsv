import GlobalBranchHistory::*;
import FoldedHistory::*;
import BranchParams::*;
import LFSR::*;
import Assert::*;
import StmtFSM::*;

typedef 10 FoldingSize;


(* synthesize *)
module mkHistoryTestBench(Empty);
    GlobalBranchHistory#(GlobalHistoryLength) gb <- mkGlobalBranchHistory;
    FoldedHistory#(FoldingSize) fh <- mkFoldedHistory(20);
    LFSR#(Bit#(16)) lfsr <- mkLFSR_16;

    Reg#(Bool) starting <- mkReg(True);
    Reg#(UInt#(10)) count <- mkReg(0);
    Reg#(Bit#(1)) x <- mkReg(0);

    Reg#(Bit#(FoldingSize)) last_1 <- mkReg(0);
    Reg#(Bit#(FoldingSize)) last_2 <- mkReg(0);
    Reg#(Bit#(FoldingSize)) last_3 <- mkReg(0);

    Reg#(Bit#(GlobalHistoryLength)) last_global_1 <- mkReg(0);
    Reg#(Bit#(GlobalHistoryLength)) last_global_2 <- mkReg(0);
    Reg#(Bit#(GlobalHistoryLength)) last_global_3 <- mkReg(0);

    Reg#(Bit#(10)) historyToForm <- mkReg(0);

    rule start(starting);
        lfsr.seed(9);
        starting <= False;
    endrule

   
 
    Stmt testRecovery1 = (seq
            last_1 <= 0;
            last_2 <= 0;
            last_3 <= 0;
            count <= 0;
            for(count <= 0; count < 200; count <= count + 1) action
                    Bit#(1) value = lfsr.value[0];
                    lfsr.next;
                    
                    gb.addHistory(value);
                    fh.updateHistory(gb, value);
                    if(count == 200) begin
                        $finish(0);
                    end
                    count <= count +1;
                    
                    $display("----------- %d ---------------", count);
                    $display("Global history %b\n", gb.history);   
                    $display("Folding history %b\n", fh.history);  
                    //$display("Folded history %b\n", fh.history);
                    
            
                    if(count % 33 == 0) begin
                        let rec <-  fh.recoverFrom[0].undo;
                        let recGlobal <-  gb.recoverFrom[0].undo;
                        $display("Rec %b\n", recGlobal);   
                        dynamicAssert(last_global_1 == recGlobal, "Global failure");
                        
                        $display("%b %b\n", fh.history, fh.recoveredHistory); 
                        
                        // Check EHRs working
                        dynamicAssert(rec == fh.recoveredHistory, "Read not matching recovery");
                        //Check recovery working
                        dynamicAssert(last_1 == rec, "Folding history recovery incorrect");
                    end else begin
                        last_3 <= last_2;
                        last_2 <= last_1;
                        last_1 <= fh.history;
                        last_global_3 <= last_global_2;
                        last_global_2 <= last_global_1;
                        last_global_1 <= gb.history;
                    end
                endaction
    endseq);

    Stmt formHistory = (seq
        gb.debugInitialise(zeroExtend(8'b0));
        fh.debugInitialise(zeroExtend(8'b0));
        for(count <= 0; count < 10; count <= count + 1) action
            Bit#(1) value = historyToForm[count];
            gb.addHistory(value);
            fh.updateHistory(gb, value);
        endaction
    
    endseq);

    FSM formHistoryFSM <- mkFSM(formHistory);

    Stmt recoverThenUpdate = (seq
    // folded size = 10    
    //FoldedHistory#(FoldingSize) fh <- mkFoldedHistory(20);
        historyToForm <= 10'b1011010111;
        formHistoryFSM.start;
        formHistoryFSM.waitTillDone;
        action
            Integer rec = 3;
            let a <- gb.recoverFrom[rec-1].undo;
            let b <- fh.recoverFrom[rec-1].undo;
            gb.addHistory(1'b1);
            fh.updateHistory(gb, 1'b1);

            // Read for prediction
            let a <- fh.history
        endaction

        //1011010111
        //1010111   

        action
            Integer rec = 3;
            $display("Global %b\n", gb.history);
            $display("Folded %b\n", fh.history);

            Bit#(10) prevState = {truncateLSB(reverseBits(historyToForm << rec) << 1), 1'b1};
            $display("Expected %b\n", prevState);
            dynamicAssert(prevState == fh.history[9:0], "Recover and update folding history failed");
            dynamicAssert(prevState == gb.history[9:0], "Recover and update folding global failed");
        endaction
        
        
    endseq);

    FSM testRecovery1FSM <- mkFSM(testRecovery1);
    FSM recoverThenUpdateFSM <- mkFSM(recoverThenUpdate);
    
    Stmt stmt = seq     
        lfsr.seed(9);
        testRecovery1FSM.start;
        testRecovery1FSM.waitTillDone;

        $display("--------- Test recovery then update ---------\n");
        recoverThenUpdateFSM.start;
        recoverThenUpdateFSM.waitTillDone;
    endseq;

    mkAutoFSM(stmt);
endmodule