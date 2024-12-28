import GlobalBranchHistory::*;
import FoldedHistory::*;
import BrPred::*;
import BranchParams::*;
import Util::*;
import RegFile::*;


`define MAX_TAGGED 12

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

typedef union tagged {
    TaggedTableEntry#(9) Tag9;
    TaggedTableEntry#(10) Tag10;
    TaggedTableEntry#(11) Tag11;
    TaggedTableEntry#(12) Tag12;
} TaggedEntrySizes deriving(Bits);


function Bool takenFromCounter(PredCtr ctr);
    return unpack(pack(ctr)[valueOf(TSub#(PredCtrSz,1))]);
endfunction


// 100
// 011
function Bool weakCounter(PredCtr ctr);
    return (pack(ctr) == (1 << valueOf(TSub#(PredCtrSz,1)))) || (pack(ctr) == ((1 << valueOf(TSub#(PredCtrSz,1)))-1));
endfunction

interface TaggedTable#(numeric type indexSize, numeric type tagSize, numeric type historyLength);
    method TaggedTableEntry#(tagSize) access_entry(Addr pc);
    method TaggedTableEntry#(`MAX_TAGGED) access_wrapped_entry(Addr pc);
    method Tuple2#(Bit#(tagSize), Bit#(indexSize)) trainingInfo(Addr pc); // To be used in training

    method Action updateHistory(GlobalBranchHistory#(GlobalHistoryLength) global, Bit#(1) taken);
    method ActionValue#(Bit#(TAdd#(tagSize, indexSize))) recoverHistory(Bit#(MaxSpecSize) numRecovery);

    method Action updateEntry(Bit#(indexSize) index, Bit#(tagSize) tag, Bool correct, UsefulCtrUpdate usefulUpdate);
    
    // Only done on misprediction
    method Action decrementUsefulCounter(Addr pc);

    method Action allocateEntry(Addr pc, Bool taken);

    /// Debug
    `ifdef DEBUG
        method Action debugUnsetEntry(Addr pc);
        method TaggedTableEntry#(tagSize) debugGetEntry(Bit#(indexSize) index);
    `endif
endinterface




module mkTaggedTable(TaggedTable#(indexSize, tagSize, historyLength)) provisos(
    Add#(a__, indexSize, 64), 
    Add#(b__, tagSize, 64), 
    Add#(indexSize, tagSize, foldedSize),
    Add#(c__, tagSize, `MAX_TAGGED));
    


    FoldedHistory#(TAdd#(tagSize, indexSize)) folded <- mkFoldedHistory(valueOf(historyLength));
    RegFile#(Bit#(indexSize), TaggedTableEntry#(tagSize)) tab <- mkRegFileWCF(0, maxBound);

    function Tuple2#(Bit#(tagSize), Bit#(indexSize)) getHistory(Bool recovered, Addr pc);
        Bit#(TAdd#(tagSize, indexSize)) hist = 0;
        if(recovered)
            hist = folded.recoveredHistory;
        else 
            hist = folded.history;

        let index = hist[valueOf(indexSize)-1:0] ^ truncate(pc >> 2);
        let tag = hist[valueOf(tagSize)+valueOf(indexSize)-1:valueOf(indexSize)+1] ^ truncate(pc >> 2);
        return tuple2(tag, index);
    endfunction



    // ----------------- DEBUG
    `ifdef DEBUG
    /*rule debug(False);
        $display("Folded: %b\n", folded.history);
    endrule*/
    
    method TaggedTableEntry#(tagSize) debugGetEntry(Bit#(indexSize) index);
        return tab.sub(index);
    endmethod

    method Action debugUnsetEntry(Addr pc);
        match {.tag, .index} = getHistory(True, pc);
        tab.upd(index, TaggedTableEntry{tag: 0, predictionCounter:0, usefulCounter:0});
    endmethod
    `endif
    
    
    
    // ----------------- DEBUG



    method Action updateHistory(GlobalBranchHistory#(GlobalHistoryLength) global, Bit#(1) taken) = folded.updateHistory(global, taken);
    method ActionValue#(Bit#(foldedSize)) recoverHistory(Bit#(MaxSpecSize) numRecovery) = folded.recoverFrom[numRecovery].undo;

  
    method Tuple2#(Bit#(tagSize), Bit#(indexSize)) trainingInfo(Addr pc); // To be used in training
        return getHistory(False, pc);
    endmethod

    method TaggedTableEntry#(tagSize) access_entry(Addr pc);
         // Shift necessary?
        Bit#(indexSize) index = folded.history[valueOf(indexSize)-1:0] ^ truncate(pc >> 2);
        return tab.sub(index);
    endmethod

    method TaggedTableEntry#(`MAX_TAGGED) access_wrapped_entry(Addr pc);
        // Shift necessary?
       Bit#(indexSize) index = folded.history[valueOf(indexSize)-1:0] ^ truncate(pc >> 2);
       TaggedTableEntry#(tagSize) entry = tab.sub(index);
       TaggedTableEntry#(`MAX_TAGGED) ret = TaggedTableEntry{tag: zeroExtend(entry.tag), predictionCounter: entry.predictionCounter, usefulCounter: entry.usefulCounter};
       return ret;
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

    
    method Action decrementUsefulCounter(Addr pc);
        match {.tag, .index} = getHistory(True, pc); // Need to use the recovered history!
        // Idea - seperate the useful counters? or some other way of doing this without a read. Could instead drag useful counters.
        TaggedTableEntry#(tagSize) entry = tab.sub(index);
        entry.usefulCounter = boundedUpdate(entry.usefulCounter, False);
        tab.upd(index, entry);
    endmethod

    // 3 bits 100 011
    method Action allocateEntry(Addr pc,  Bool taken);
        
        match {.tag, .index} = getHistory(True, pc);

        $display("Tag:%b Index: %b", tag, index);
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