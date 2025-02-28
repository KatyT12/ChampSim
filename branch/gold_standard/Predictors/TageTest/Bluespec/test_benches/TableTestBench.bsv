import GlobalBranchHistory::*;
import FoldedHistory::*;
import BranchParams::*;
import LFSR::*;
import TaggedTable::*;
import Assert::*;
import StmtFSM::*;
import Vector::*;

typedef 10 FoldingSize;


(* synthesize *)
module mkTableTestBench(Empty);
    LFSR#(Bit#(16)) lfsr <- mkLFSR_16;

    Reg#(Bool) starting <- mkReg(True);
    Reg#(UInt#(10)) count <- mkReg(0);

    GlobalBranchHistory#(GlobalHistoryLength) gb <- mkGlobalBranchHistory;
    TaggedTable#(5, 5, 10) tg <- mkTaggedTable;



    
        
        

    Stmt stmt = seq     
        lfsr.seed(9); 
        // Test allocation
        action
        $display("Allocation\n");
            tg.allocateEntry(13,  True);
        endaction

        action
            let t = tg.access_entry(13);
            $display("%d %d %d\n",t.tag, t.predictionCounter, t.usefulCounter);
        endaction

        while(count < 10) seq
            action
            $display("--  %d  --\n", count);
                Bit#(1) value = lfsr.value[0];
                lfsr.next;

                

                gb.addHistory(value);
                $display("Global history %b\n", gb.history);
                tg.updateHistory(gb, value);

                let t = tg.access_entry(13);
                $display("Normal: %d %d %d\n",t.tag, t.predictionCounter, t.usefulCounter);
                match {.a1, .a2} = tg.trainingInfo(13, False);
                $display("Normal tag %d, index %d\n",a1, a2);

                if(count % 20 == 0) begin
                    tg.updateEntry(3, 3, True, INCREMENT);
                end

                if(count % 20 == 1) begin
                    let g <- gb.recoverFrom[0].undo;
                    let r <- tg.recoverHistory(0);
                    $display("Recovered %b\n", r);
                    
                    tg.allocateEntry(13, False);
                    let t = tg.access_entry(13);
                    $display("After recovery %d %d %d\n",t.tag, t.predictionCounter, t.usefulCounter);
                    
                end
                count <= count +1;
            endaction
            endseq

    endseq;

    

  mkAutoFSM(stmt);
endmodule