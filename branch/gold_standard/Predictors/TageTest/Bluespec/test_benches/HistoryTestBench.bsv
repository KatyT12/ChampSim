import GlobalBranchHistory::*;
import FoldedHistory::*;
import BranchParams::*;
import BrPred::*;
import ProcTypes::*;

import LFSR::*;
import Assert::*;
import StmtFSM::*;

typedef 10 FoldingSize;

(* synthesize *)
module mkHistoryTestBench(Empty);
    GlobalBranchHistory#(GlobalHistoryLength) gb <- mkGlobalBranchHistory;
    FoldedHistory#(FoldingSize) fh <- mkFoldedHistory(20, gb);
    FoldedHistory#(FoldingSize) fhSmall <- mkFoldedHistory(5, gb);
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

    Reg#(Bit#(SupSize)) multiPredictionResult <- mkReg(0);
    Reg#(SupCnt) multiPredictionCount <- mkReg(2);
    Reg#(Bit#(FoldingSize)) foldingTestResult <- mkReg(0);
    Reg#(Bit#(FoldingSize)) fhInit <- mkReg(0);
    Reg#(Bit#(GlobalHistoryLength)) gbInit <- mkReg(0);

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
                    gb.addHistoryBits(zeroExtend(value), 1);
                    fh.updateHistory(zeroExtend(value), 1);
                    if(count == 200) begin
                        $finish(0);
                    end
                    
                    $display("----------- %d ---------------", count);
                    $display("Global history %b\n", gb.history);   
                    $display("Folding history %b\n", fh.history);  
                    //$display("Folded history %b\n", fh.history);

                    dynamicAssert(fh.history == fh.recomputedHistory(False, tagged Invalid), "Folding is incorrect");
                    
                    if(count % 33 == 0) begin
                        let rec <-  fh.recoverFrom[2].debugUndo;
                        let recGlobal <-  gb.recoverFrom[2].debugUndo;
                        $display("Rec %b\n", recGlobal);   
                        dynamicAssert(last_global_3 == recGlobal, "Global recovery incorrect");
                        
                        $display("%b %b\n", fh.history, fh.recoveredHistory); 
                        
                        // Check EHRs working
                        dynamicAssert(rec == fh.recoveredHistory, "Read not matching recovery");
                        //Check recovery working
                        dynamicAssert(last_3 == rec, "Folding history recovery incorrect");

                        dynamicAssert(fh.recoveredHistory == fh.recomputedHistory(True, tagged Invalid), "Folding is incorrect after recovered");
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
            gb.addHistoryBits(zeroExtend(value), 1);
            fh.updateHistory(zeroExtend(value), 1);
        endaction
    endseq);


    Stmt testMultiPrediction = (seq
        gb.debugInitialise(zeroExtend(8'b0));
        gb.addHistoryBits(multiPredictionResult, multiPredictionCount);
        
        action
        let shift = fromInteger(valueOf(SupSize)) - multiPredictionCount;
        Bit#(SupSize) expected = reverseBits(multiPredictionResult) >> shift;
        $display("Global %b\n", gb.history[3:0]);
        $display("Expected %b\n", expected);
        dynamicAssert(expected == gb.history[valueOf(SupSize)-1:0], "Updating 2 bits failed");
        endaction
    endseq);
    

    FSM testMultiPredictionFSM <- mkFSM(testMultiPrediction);
    
    Stmt testGlobalMultipleUpdate = (seq
        $display("--------------- Test Global Multiple Update -----------------\n");
        multiPredictionCount <= 1;
        multiPredictionResult <= 4'b1;

        testMultiPredictionFSM.start;
        testMultiPredictionFSM.waitTillDone;

        multiPredictionCount <= 1;
        multiPredictionResult <= 4'b0;

        testMultiPredictionFSM.start;
        testMultiPredictionFSM.waitTillDone;

        
        if(valueOf(SupSize) > 1) seq
            multiPredictionCount <= 2;
            multiPredictionResult <= 4'b10;

            testMultiPredictionFSM.start;
            testMultiPredictionFSM.waitTillDone;

            multiPredictionResult <= 4'b11;
            testMultiPredictionFSM.start;
            testMultiPredictionFSM.waitTillDone;

            multiPredictionResult <= 4'b00;
            testMultiPredictionFSM.start;
            testMultiPredictionFSM.waitTillDone;
        endseq

        if(valueOf(SupSize) > 3) seq
            multiPredictionCount <= 3;
            multiPredictionResult <= 4'b10;

            testMultiPredictionFSM.start;
            testMultiPredictionFSM.waitTillDone;

            multiPredictionResult <= 4'b11;
            testMultiPredictionFSM.start;
            testMultiPredictionFSM.waitTillDone;

            multiPredictionResult <= 4'b0011;
            testMultiPredictionFSM.start;
            testMultiPredictionFSM.waitTillDone;

            multiPredictionResult <= 4'b1111;
            testMultiPredictionFSM.start;
            testMultiPredictionFSM.waitTillDone;

            multiPredictionResult <= 4'b1001;
            testMultiPredictionFSM.start;
            testMultiPredictionFSM.waitTillDone;
        endseq
    endseq);

    Stmt testMultiPredictionFolded = (seq
        gbInit <= gb.history;
        fhInit <= fh.history;
        
        dynamicAssert(fh.history == fh.recomputedHistory(False, tagged Invalid), "Read not matching recovery 1");
        $display("Global hist 1 %b\n", gb.history);
        $display("Folding hist 1 %b\n", fh.history);
        //11
        action
        gb.addHistoryBits(multiPredictionResult, multiPredictionCount);
        fh.updateHistory(multiPredictionResult, multiPredictionCount);
        endaction
        
        $display("%b %b\n",fh.history, fh.recomputedHistory(False, tagged Invalid));
        $display("Global hist 2 %b\n", gb.history);
        dynamicAssert(fh.history == fh.recomputedHistory(False, tagged Invalid), "Read not matching recovery 2\n");
        
        

        
        foldingTestResult <= fh.history;

        gb.debugInitialise(gbInit);
        fh.debugInitialise(fhInit);

        dynamicAssert(fh.history == fh.recomputedHistory(False, tagged Invalid), "Read not matching recovery 3");

        for(count <= 0; count < fromInteger(valueOf(SupSize)); count <= count + 1) seq
            if(pack(count) < zeroExtend(pack(multiPredictionCount))) action
                gb.addHistoryBits(zeroExtend(multiPredictionResult[count]), 1);
                fh.updateHistory(zeroExtend(multiPredictionResult[count]), 1);
            endaction
        endseq
        
        dynamicAssert(fh.history == fh.recomputedHistory(False, tagged Invalid), "Read not matching recovery 4");
        $display("Got: %b\n", foldingTestResult);
        $display("Expected: %b\n", fh.history);
        dynamicAssert(fh.history == foldingTestResult, "Multiple folding history update failed");
    endseq);

    FSM testMultiPredictionFoldedFSM <- mkFSM(testMultiPredictionFolded);

    Stmt testFoldedMultipleUpdate = (seq
        $display("--------------- Test Folded Multiple Update -----------------\n");
        gb.debugInitialise(zeroExtend(8'b0));
        fh.debugInitialise(zeroExtend(8'b0));
        
        if(valueOf(SupSize) > 1) seq
            multiPredictionCount <= 2;
            multiPredictionResult <= 4'b10;

            testMultiPredictionFoldedFSM.start;
            testMultiPredictionFoldedFSM.waitTillDone;

            multiPredictionCount <= 2;
            multiPredictionResult <= 4'b11;

            testMultiPredictionFoldedFSM.start;
            testMultiPredictionFoldedFSM.waitTillDone;

            multiPredictionCount <= 2;
            multiPredictionResult <= 4'b00;

            testMultiPredictionFoldedFSM.start;
            testMultiPredictionFoldedFSM.waitTillDone;
        endseq


        for(count <= 0; count < 15; count <= count + 1) action
            Bit#(1) value = lfsr.value[0];
            lfsr.next;
            gb.addHistoryBits(zeroExtend(value), 1);
            fh.updateHistory(zeroExtend(value), 1);
        endaction
        $display("Before Global %b\n", gb.history[20:18]);
        $display("Before Folded %b\n", fh.history);

        multiPredictionCount <= 2;
        multiPredictionResult <= 4'b11;
        
        testMultiPredictionFoldedFSM.start;
        testMultiPredictionFoldedFSM.waitTillDone;
    endseq);

    FSM formHistoryFSM <- mkFSM(formHistory);
    FSM testGlobalMultipleUpdateFSM <- mkFSM(testGlobalMultipleUpdate);
    FSM testFoldedMultipleUpdateFSM <- mkFSM(testFoldedMultipleUpdate);

    Stmt recoverThenUpdate = (seq
    // folded size = 10    
    //FoldedHistory#(FoldingSize) fh <- mkFoldedHistory(20);
        historyToForm <= 10'b1011010111;
        formHistoryFSM.start;
        formHistoryFSM.waitTillDone;
        $display("Global %b\n", gb.history);
        $display("Before update Folded %b\n", fh.history);

        dynamicAssert(fh.history == fh.recomputedHistory(False, tagged Invalid), "Read not matching recovery 4");
        action
            Integer rec = 3;
            Bit#(10) prevState = reverseBits(historyToForm << rec);
            Bit#(10) newState = {truncateLSB(prevState << 1), 1'b1};


            let a <- gb.recoverFrom[rec-1].debugUndo;
            let b <- fh.recoverFrom[rec-1].debugUndo;
            gb.updateRecoveredHistory(1'b1);
            fh.updateRecoveredHistory(1'b1);

            
            // Read for prediction
            let c = fh.history;
            dynamicAssert(c == reverseBits(historyToForm), "");

            // Read for index or whatever, after recovery
            let d = fh.recoveredHistory;
            dynamicAssert(d == prevState, "");

            //This should not make any difference
            gb.addHistoryBits(zeroExtend(1'b0), 1);
            fh.updateHistory(zeroExtend(1'b0), 1);
        endaction
        dynamicAssert(fh.history == fh.recomputedHistory(False, tagged Invalid), "Read not matching recovery 4");

        //1011010111
        //1010111   
        $display("After update folded %b\n", fh.history);
        action
            Integer rec = 3;
            $display("Global %b\n", gb.history);
            $display("Folded %b\n", fh.history);

            Bit#(10) prevState = {truncateLSB(reverseBits(historyToForm << rec) << 1), 1'b1};
            $display("Expected %b\n", prevState);
            dynamicAssert(prevState == fh.history[9:0], "Recover and update folding history failed");
            dynamicAssert(prevState == gb.history[9:0], "Recover and update folding global failed");
        endaction
        dynamicAssert(fh.history == fh.recomputedHistory(False, tagged Invalid), "Read not matching recovery 4");
    endseq);

    FSM testRecovery1FSM <- mkFSM(testRecovery1);
    FSM recoverThenUpdateFSM <- mkFSM(recoverThenUpdate);


    Stmt sequentialUpdates = (seq
        historyToForm <= 10'b1011010111;
        formHistoryFSM.start;
        formHistoryFSM.waitTillDone;
        
        
        dynamicAssert(fh.history == fh.recomputedHistory(False, tagged Invalid), "Read not matching recovery 4");

        for(count <= 0; count < 15; count <= count + 1) action
            Bit#(1) value = lfsr.value[0];
            lfsr.next;
            gb.addHistoryBits(zeroExtend(value), 1);
            fh.updateHistory(zeroExtend(value), 1);
        endaction
        // Original
        foldingTestResult <= fh.history;
        last_global_1 <= gb.history;
        
        $display("Global %b\n", gb.history);
        $display("Before update Folded %b\n", fh.history);

        for(count <= 0; count < 5; count <= count + 1) action
            Bit#(1) value = lfsr.value[0];
            lfsr.next;
            gb.addHistoryBits(zeroExtend(value), 1);
            fh.updateHistory(zeroExtend(value), 1);

            //$display("After %d %b\n", count, fh.history);
        endaction
        dynamicAssert(fh.history == fh.recomputedHistory(False, tagged Invalid), "Read not matching recovery 4");

        action
        gb.recoverFrom[2].undo;
        fh.recoverFrom[2].undo;
        gb.updateRecoveredHistory(1);
        fh.updateRecoveredHistory(1);
        endaction
        dynamicAssert(fh.history == fh.recomputedHistory(False, tagged Invalid), "Read not matching recovery 4");

        action
            $display("%b\n",fh.history);
        endaction

        action
        gb.recoverFrom[2].undo;
        fh.recoverFrom[2].undo;
        endaction

        dynamicAssert(fh.history == fh.recomputedHistory(False, tagged Invalid), "Read not matching recovery 4");

        action
            $display("%b\n",fh.history);
        endaction
        dynamicAssert(gb.history == last_global_1, "Global failure on sequential mispredictions");
        dynamicAssert(fh.history == foldingTestResult, "Folding failure on sequential mispredictions");
    endseq);

    Stmt misc = (seq
        $display("---- MISC ----");
        gb.debugInitialise(zeroExtend(20'b11100));
        fhSmall.debugInitialise(10'b11100);

        // Multiple
        action
        gb.addHistoryBits(4'b00,2);
        fhSmall.updateHistory(4'b00,2);
        endaction

        $display("%b\n",fhSmall.history);

        gb.debugInitialise(zeroExtend(20'b11100));
        fhSmall.debugInitialise(10'b11100);

        action
        gb.addHistoryBits(4'b0,1);
        fhSmall.updateHistory(4'b0,1);
        endaction
        
        action
        gb.addHistoryBits(4'b0,1);
        fhSmall.updateHistory(4'b0,1);
        endaction

        $display("%b\n",fhSmall.history);
        dynamicAssert(fh.history == foldingTestResult, "Folding failure on sequential mispredictions");

        gb.debugInitialise(zeroExtend(20'b10100));
        fhSmall.debugInitialise(10'b10100);
        action
        gb.addHistoryBits(4'b00,2);
        fhSmall.updateHistory(4'b00,2);
        endaction
        $display("%b\n",fhSmall.history);
        $display("%b\n",fhSmall.recomputedHistory(False, tagged Invalid));

        dynamicAssert(fh.history == foldingTestResult, "Folding failure on sequential mispredictions");

        gb.debugInitialise(zeroExtend(20'b1001));
        fhSmall.debugInitialise(10'b1001);
        action
        gb.addHistoryBits(4'b00,2);
        fhSmall.updateHistory(4'b00,2);
        endaction
        $display("%b\n",fhSmall.history);
        $display("%b\n",fhSmall.recomputedHistory(False, tagged Invalid));

    endseq);

    FSM sequentialUpdatesFSM <- mkFSM(sequentialUpdates);
    FSM miscFSM <- mkFSM(misc);
    
    Stmt stmt = seq     
        lfsr.seed(9);
        testRecovery1FSM.start;
        testRecovery1FSM.waitTillDone;

        $display("--------- Test recovery then update ---------\n");
        recoverThenUpdateFSM.start;
        recoverThenUpdateFSM.waitTillDone;

        testGlobalMultipleUpdateFSM.start;
        testGlobalMultipleUpdateFSM.waitTillDone;

        testFoldedMultipleUpdateFSM.start;
        testFoldedMultipleUpdateFSM.waitTillDone;

        $display("-------------- Test Sequential updates --------------\n");
        sequentialUpdatesFSM.start;
        sequentialUpdatesFSM.waitTillDone;

        miscFSM.start;
        miscFSM.waitTillDone;

    endseq;

    mkAutoFSM(stmt);
endmodule