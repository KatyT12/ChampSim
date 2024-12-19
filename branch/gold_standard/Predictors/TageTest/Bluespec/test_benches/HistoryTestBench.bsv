import GlobalBranchHistory::*;
import FoldedHistory::*;
import BranchParams::*;
import LFSR::*;
import Assert::*;

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

    rule start(starting);
        lfsr.seed(9);
        starting <= False;
    endrule

    //(* conflict_free = "gb_updateHistory, run" *)
    rule run (!starting);
        //x <= ~x;
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
            let rec <-  fh.recoverFrom[1].undo;
            let recGlobal <-  gb.recoverFrom[1].undo;
            $display("Rec %b\n", recGlobal);   
            dynamicAssert(last_global_2 == recGlobal, "Global failure");
            
            $display("%b %b\n", fh.history, fh.recoveredHistory); 
            
            // Check EHRs working
            dynamicAssert(rec == fh.recoveredHistory, "Read not matching recovery");
            //Check recovery working
            dynamicAssert(last_2 == rec, "Folding history recovery incorrect");
        end else begin
            last_3 <= last_2;
            last_2 <= last_1;
            last_1 <= fh.history;
            last_global_3 <= last_global_2;
            last_global_2 <= last_global_1;
            last_global_1 <= gb.history;
        end


        
    endrule
endmodule