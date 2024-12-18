import GlobalBranchHistory::*;
import FoldedHistory::*;
import BrPred::*;
import BranchParams::*;
import RegFile::*;

/*
typedef struct {
    Entry counter;
    Addr pc;
} TageTrainInfo deriving(Bits, Eq, FShow);
*/

typedef 3 PredCtrSz;
typedef Bit#(PredCtrSz) PredCtr;

typedef 2 UsefulCtrSz;
typedef Bit#(UsefulCtrSz) UsefulCtr;

typedef struct {
    PredCtr predictionCounter;
    UsefulCtr usefulCounter;
    Bit#(tagSize) tag;
} TaggedTableEntry#(numeric type tagSize) deriving(Bits, Eq, FShow);

typedef enum {
    INCREMENT,
    PRESERVE,
    DECREMENT
} UsefulCtrUpdate deriving (Bits, Eq, FShow);

interface TaggedTable#(numeric type tagSize, numeric type indexSize, numeric type historyLength);
    method TaggedTableEntry#(tagSize) access_entry(Addr pc);
    method Tuple2#(Bit#(tagSize), Bit#(indexSize)) trainingInfo(Addr pc); // To be used in training

    method Action updateHistory(GlobalBranchHistory#(GlobalHistoryLength) global, Bit#(1) taken);
    method ActionValue#(Bit#(TAdd#(tagSize, indexSize))) recoverHistory(Bit#(MaxSpecSize) numRecovery);


    // For now drag along whole entry that we want to update with
    // Awkwardness with replacing newer updates to that allocation. You might want to actually check the tag still matches
    /*
        Decision - drag along original entry, meaning updates in between can be replaced.
        
        Because of register ports, for now I will update by actually reading the entry and choosing incrementing/decrementing rather than
        just replacing the entry or doing any sort of read of the counters.

        There is also the issue of replacing data as mentioned above

        method Action update_entry(Bit#(indexSize) index, TaggedTableEntry newEntry);
    */
    
    method Action updateEntry(Bit#(indexSize) index, Bit#(tagSize) tag, Bool correct, UsefulCtrUpdate usefulUpdate);
    method Action allocateEntry(Bit#(indexSize) index, Bit#(tagSize) tag, Bool taken);
endinterface




module mkTaggedTable(TaggedTable#(tagSize, indexSize, historyLength)) provisos(
    Add#(a__, indexSize, 64), 
    Add#(indexSize, tagSize, foldedSize));


    FoldedHistory#(TAdd#(tagSize, indexSize)) folded <- mkFoldedHistory(valueOf(historyLength));
    RegFile#(Bit#(indexSize), TaggedTableEntry#(tagSize)) tab <- mkRegFileWCF(0, maxBound);

    function Bit#(n) boundedUpdate(Bit#(n) counter, Bool increment);
        if(increment) begin
            return counter == maxBound ? maxBound : counter + 1;
        end
        else begin
            return counter == 0 ? 0 : counter - 1;
        end
    endfunction

    rule debug;
        $display("Folded: %b\n", folded.history);
    endrule

    method Action updateHistory(GlobalBranchHistory#(GlobalHistoryLength) global, Bit#(1) taken) = folded.updateHistory(global, taken);
    method ActionValue#(Bit#(foldedSize)) recoverHistory(Bit#(MaxSpecSize) numRecovery) = folded.recoverFrom[numRecovery].undo;

    method Tuple2#(Bit#(tagSize), Bit#(indexSize)) trainingInfo(Addr pc); // To be used in training
        let index = folded.history[valueOf(indexSize)-1:0];
        let tag = folded.history[valueOf(tagSize)+valueOf(indexSize)-1:valueOf(indexSize)+1];
        return tuple2(tag, index);
    endmethod

    method TaggedTableEntry#(tagSize) access_entry(Addr pc);
         // Shift necessary?
        Bit#(indexSize) index = folded.history[valueOf(indexSize)-1:0] ^ truncate(pc >> 2);
        return tab.sub(index);
    endmethod


    method Action updateEntry(Bit#(indexSize) index, Bit#(tagSize) tag, Bool correct, UsefulCtrUpdate usefulUpdate);
        let currentEntry = tab.sub(index);
        if (currentEntry.tag == tag) begin
            TaggedTableEntry#(tagSize) newEntry = currentEntry;   
            // Update prediction and useful counter
            newEntry.predictionCounter = boundedUpdate(currentEntry.predictionCounter, correct);
            if (usefulUpdate != PRESERVE) begin
                newEntry.usefulCounter = boundedUpdate(currentEntry.usefulCounter, usefulUpdate == INCREMENT);
            end

            // Probably completely unnecessary and unhelpful
            if ({newEntry.predictionCounter, newEntry.usefulCounter} != {currentEntry.predictionCounter, currentEntry.usefulCounter}) begin
                tab.upd(index, newEntry);            
            end
        end
    endmethod

    // 3 bits 100 011
    method Action allocateEntry(Bit#(indexSize) index, Bit#(tagSize) tag, Bool taken);
        // Weakly taken = 100 - 1, weakly not taken = 100 - 1
        Bit#(PredCtrSz) counter_init = 1 << (valueOf(PredCtrSz)-1);
        if (!taken) begin
            counter_init = (1 << (valueOf(PredCtrSz)-1))-1;
        end
        
        TaggedTableEntry#(tagSize) toWrite = TaggedTableEntry{predictionCounter: counter_init, usefulCounter:  0, tag: tag};
        tab.upd(index, toWrite);
    endmethod
    //method Tuple2#(Bit#(tagSize), Bit#(indexSize)) trainingInfo(Addr pc);

    //endmethod

endmodule