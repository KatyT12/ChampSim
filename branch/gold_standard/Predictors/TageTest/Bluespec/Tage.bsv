import BrPred::*;
import RegFile::*;
import LFSR::*;
import Vector::*;
import List::*;
import HList::*;

import TaggedTable::*;
import GlobalBranchHistory::*;

/*
export DirPredTrainInfo(..);
export TageTrainInfo(..);
export Addr;
export Entry;
export PCIndex;
export PCIndexSz;
export Tage;
export mkTage;
*/

// Not a reasonable solution


`define WRAP_CODE(body) \
    action /* body */ endaction

`define WRAP_CODE_NON_ACTION(body) \
    /* body */

`define CASE_ALL_TABLES(varName, body) \
    case (varName) matches \
    tagged T_9_9_5 .t : begin  \
        `WRAP_CODE_NON_ACTION(body) \
    end \
    tagged T_9_9_9 .t : begin \
        `WRAP_CODE_NON_ACTION(body) \
    end \
    tagged T_9_10_15 .t : begin \
        `WRAP_CODE_NON_ACTION(body) \
    end \
    tagged T_9_10_25 .t : begin \
        `WRAP_CODE_NON_ACTION(body) \
    end \
    tagged T_9_11_44 .t : begin \
        `WRAP_CODE_NON_ACTION(body) \
    end \
    tagged T_9_11_76 .t : begin \
        `WRAP_CODE_NON_ACTION(body) \
    end \
    tagged T_9_12_130 .t : begin \
        `WRAP_CODE_NON_ACTION(body) \
    end \
    endcase \

`define MAX_TAGGED 12

typedef 12 PCIndexSz;
typedef Bit#(PCIndexSz) PCIndex;
typedef Bit#(2) Entry;

typedef Tuple2#(Maybe#(Tuple2#(Bit#(TLog#(num)), TaggedTableEntry#(`MAX_TAGGED))), Maybe#(Tuple2#(Bit#(TLog#(num)), TaggedTableEntry#(`MAX_TAGGED)))) PredictionTableInfo#(numeric type num);

typedef struct {
    Entry counter;
    PCIndex pc;
} TageTrainInfo deriving(Bits, Eq, FShow);

typedef TageTrainInfo DirPredTrainInfo;

// Abolutely terrible, is there an easier way to parametrise this?

typedef union tagged {
    TaggedTable#(9,9,5) T_9_9_5;
    TaggedTable#(9,9,9) T_9_9_9;
    TaggedTable#(9,10,15) T_9_10_15;
    TaggedTable#(9,10,25) T_9_10_25;
    TaggedTable#(9,11,44) T_9_11_44;
    TaggedTable#(9,11,76) T_9_11_76;
    TaggedTable#(9,12, 130) T_9_12_130;
} ChosenTaggedTables deriving(Bits);

typedef union tagged {
    TaggedTableEntry#(9) Tag9;
    TaggedTableEntry#(10) Tag10;
    TaggedTableEntry#(11) Tag11;
    TaggedTableEntry#(12) Tag12;
} TaggedEntrySizes deriving(Bits);

interface Tage#(numeric type numTables);
    interface DirPredictor#(TageTrainInfo) dirPredInterface;
    
    
    
    `ifdef DEBUG
        method Action debugTables(Addr pc);
        method Action debugAllocate(Addr pc, Bit#(TLog#(numTables)) tableNum);
        method Action debugResetEntry(Addr pc, Bit#(TLog#(numTables)) tableNum);
        method PredictionTableInfo#(numTables) debugPredAltpred;
    `endif
endinterface


module mkTage(Tage#(numTables));
    TaggedTable#(9,9,5)     t1 <- mkTaggedTable;
    TaggedTable#(9,9,9)     t2 <- mkTaggedTable;
    TaggedTable#(9,10,15)   t3 <- mkTaggedTable;
    TaggedTable#(9,10,25)   t4 <- mkTaggedTable;
    TaggedTable#(9,11,44)   t5 <- mkTaggedTable;
    TaggedTable#(9,11,76)   t6 <- mkTaggedTable;
    TaggedTable#(9,12,130)  t7 <- mkTaggedTable;

    //ChosenTaggedTables a <- T_9_9_5(mkTaggedTable);
    //Vector#(1, ChosenTaggedTables) taggedTablesVector = cons(T_9_9_5(mkTaggedTable), nil);
    //valueOf(numTables)
    Vector#(7, ChosenTaggedTables) taggedTablesVector = cons(T_9_9_5(t1), cons(T_9_9_9(t2), cons(T_9_10_15(t3), cons(T_9_10_25(t4), cons(T_9_11_44(t5), cons(T_9_11_76(t6), cons(T_9_12_130(t7), nil)))))));
    Reg#(Addr) currentPc <- mkRegU;

    Vector#(SupSize, DirPred#(TageTrainInfo)) predIfc;

    function Tuple2#(Vector#(numTables,Maybe#(Bit#(TLog#(numTables)))), Vector#(numTables,Maybe#(Bit#(TLog#(numTables))))) treeFindPred(Integer len, Integer depth, Vector#(numTables,Maybe#(Bit#(TLog#(numTables)))) entries_compare, Vector#(numTables,Maybe#(Bit#(TLog#(numTables)))) altpred_compare);
        
        if (depth == 0) return tuple2(entries_compare, altpred_compare);
        else begin
            Vector#(numTables,Maybe#(Bit#(TLog#(numTables)))) pred = replicate(tagged Invalid);
            Vector#(numTables,Maybe#(Bit#(TLog#(numTables)))) altpred = replicate(tagged Invalid);

                // Is this compile time or is it forced to be sequential???
            for (Integer j = 0; j < 2*(len/2); j = j + 2) begin
                if (entries_compare[j+1] matches tagged Valid .x) begin
                    //$display("DEBUG %d %d\n", i, j);
                    //$display("DEBUG COMPARE ", fshow(entries_compare[j])," ", fshow(entries_compare[j+1]), "\n");
                    if(altpred_compare[j+1] matches tagged Valid .x)
                        altpred[j / 2] = altpred_compare[j+1];
                    else
                        altpred[j / 2] = entries_compare[j];  
                    pred[j / 2] = entries_compare[j+1];
                    
                end
                else begin
                    pred[j / 2] = entries_compare[j];
                    altpred[j / 2] = altpred_compare[j];
                end
            end
            if (len % 2 == 1) begin
                //$display("Length %d\n", len);
                pred[(len/2)] = entries_compare[len-1];
                altpred[(len/2)] = tagged Invalid;
            end
            Integer len2 = (len / 2) + (len % 2);
        return treeFindPred(len2, depth - 1, pred, altpred);
        end
    endfunction

    function PredictionTableInfo#(numTables) find_pred_altpred;
        Vector#(numTables,Maybe#(Bit#(TLog#(numTables)))) entries_compare = replicate(tagged Invalid);
        Vector#(numTables,Maybe#(Bit#(TLog#(numTables)))) altpred_compare = replicate(tagged Invalid);
        
        Vector#(numTables,TaggedTableEntry#(`MAX_TAGGED)) entries = replicate(TaggedTableEntry{tag:0, predictionCounter:0, usefulCounter:0});

        // Will be easiest to cache this, TaggedEntry may have different tag sizes!
        //Vector#(`NUM_TABLES,TaggedTableEntry#(tagSize)) entries <- genVector;
        
        // Retrieve all entries, check if they have a matching tag

        for(Integer i = 0; i < valueOf(numTables); i=i+1) begin
            ChosenTaggedTables tab = taggedTablesVector[i];    
            `CASE_ALL_TABLES(tab, 
            (*/
                // Could do this in one
                match {.tag, .index} = t.trainingInfo(currentPc);
                let entry = t.access_wrapped_entry(currentPc);
                
                entries[i] = entry;
                if (zeroExtend(tag) == entry.tag) begin
                    entries_compare[i] = tagged Valid fromInteger(i);
                end
                /*)
            )
        end

        Integer len = valueOf(numTables);
        match{.pred_vec, .altpred_vec} = treeFindPred(len, valueOf(TLog#(numTables)), entries_compare, altpred_compare);

        PredictionTableInfo#(numTables) ret = tuple2(tagged Invalid, tagged Invalid);
        if (pred_vec[0] matches tagged Valid .x)
            if (altpred_vec[0] matches tagged Valid .y)
                return tuple2(tagged Valid tuple2(x, entries[x]), tagged Valid tuple2(y, entries[y]));
            else
                return tuple2(tagged Valid tuple2(x, entries[x]), tagged Invalid);
        else
            return tuple2(tagged Invalid, tagged Invalid);
    endfunction
 

    for(Integer i=0; i < valueOf(SupSize); i=i+1) begin
        predIfc[i] = (interface DirPred;
        
        method ActionValue#(DirPredResult#(TageTrainInfo)) pred;
            //match {.pred, .altpred} = find_pred_altpred;
            
            match {.pred, .altpred} = find_pred_altpred;
            $display("Pred: ", fshow(pred)," AltPred: ",fshow(altpred));

            //$display("%d %d\n", a, b);

            // 
            return DirPredResult {
                taken: True,
                train: TageTrainInfo {
                    counter: 2,
                    pc: 3
                }
            };
        endmethod
        endinterface);
    end

   
    `ifdef DEBUG
    method Action debugTables(Addr pc);
        for(Integer i = 0; i < 7; i=i+1) begin
            ChosenTaggedTables tab = taggedTablesVector[i];
            `CASE_ALL_TABLES(tab, (*/match {.c, .d} = t.trainingInfo(pc); $display("%d %d\n", c, d);/*))    
        end
    endmethod


    method PredictionTableInfo#(numTables) debugPredAltpred;
        return find_pred_altpred;
    endmethod

    method Action debugAllocate(Addr pc, Bit#(TLog#(numTables)) tableNum);
        ChosenTaggedTables tab = taggedTablesVector[tableNum];
        `CASE_ALL_TABLES(tab, (*/ t.allocateEntry(pc, False); /*))
    endmethod

    method Action debugResetEntry(Addr pc, Bit#(TLog#(numTables)) tableNum);
        ChosenTaggedTables tab = taggedTablesVector[tableNum];
        `CASE_ALL_TABLES(tab, (*/ t.debugUnsetEntry(pc); /*))
    endmethod
    `endif

    interface  dirPredInterface = interface DirPredictor#(TageTrainInfo);
        interface pred = predIfc;
        method Action update(Bool taken, TageTrainInfo train, Bool mispred);
        endmethod
    
        method Action nextPc(Addr pc);
            currentPc <= pc;
        endmethod
    
        method flush = noAction;
        method flush_done = True;
    endinterface;
endmodule