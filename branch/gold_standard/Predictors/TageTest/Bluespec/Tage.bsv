import BrPred::*;
import RegFile::*;
import LFSR::*;
import Vector::*;
import List::*;

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

`define PRINT(x) $display("%d\n",x);

typedef 12 PCIndexSz;
typedef Bit#(PCIndexSz) PCIndex;
typedef Bit#(2) Entry;

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

interface Tage#(numeric type numTables);
    interface DirPredictor#(TageTrainInfo) dirPredInterface;
    
    
    
    `ifdef DEBUG
        method Action debugTables(Addr pc);
        method Action debugAllocate(Addr pc, Bit#(TLog#(numTables)) tableNum);
        method Tuple2#(Maybe#(Bit#(TLog#(numTables))), Maybe#(Bit#(TLog#(numTables)))) debugPredAltpred;
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

    function Tuple2#(Maybe#(Bit#(TLog#(numTables))), Maybe#(Bit#(TLog#(numTables)))) find_pred_altpred;
        Vector#(numTables,Maybe#(Bit#(TLog#(numTables)))) entries_compare = replicate(tagged Invalid);
        Vector#(numTables,Maybe#(Bit#(TLog#(numTables)))) altpred_compare = replicate(tagged Invalid);
        Maybe#(Bit#(TLog#(numTables))) alt_pred = tagged Invalid;

        // Will be easiest to cache this, TaggedEntry may have different tag sizes!
        //Vector#(`NUM_TABLES,TaggedTableEntry#(tagSize)) entries <- genVector;
        
        // Retrieve all entries, check if they have a matching tag


        for(Integer i = 0; i < valueOf(numTables); i=i+1) begin
            ChosenTaggedTables tab = taggedTablesVector[i];    
            `CASE_ALL_TABLES(tab, 
            (*/
                // Could do this in one
                match {.tag, .index} = t.trainingInfo(currentPc);
                let entry = t.access_entry(currentPc);
                
                //entries[i] = entry;
                if (tag == entry.tag) begin
                    entries_compare[i] = tagged Valid fromInteger(i);
                end
                /*)
            )
        end
 
        Integer len = valueOf(numTables);
        for (Integer i = 0; i < valueOf(TLog#(numTables)); i = i + 1) begin

            // Is this compile time or is it forced to be sequential???
            for (Integer j = 0; j < 2*(len/2); j = j + 2) begin
                if (entries_compare[j+1] matches tagged Valid .x) begin
                    //$display("DEBUG %d %d\n", i, j);
                    //$display("DEBUG COMPARE ", fshow(entries_compare[j])," ", fshow(entries_compare[j+1]), "\n");
                    if(altpred_compare[j+1] matches tagged Valid .x)
                        altpred_compare[j / 2] = altpred_compare[j+1];
                    else
                        altpred_compare[j / 2] = entries_compare[j];  
                    entries_compare[j / 2] = entries_compare[j+1];
                    
                end
                else begin
                    entries_compare[j / 2] = entries_compare[j];
                    altpred_compare[j / 2] = altpred_compare[j];
                end
            end
            if (len % 2 == 1) begin
                //$display("Length %d\n", len);
                entries_compare[(len/2)] = entries_compare[len-1];
                altpred_compare[(len/2)] = tagged Invalid;
            end
            len = (len / 2) + (len % 2);
        end
        //$display(fshow(entries_compare[0]), fshow(altpred_compare[0]));
        return tuple2(entries_compare[0], altpred_compare[0]);
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


    method Tuple2#(Maybe#(Bit#(TLog#(numTables))), Maybe#(Bit#(TLog#(numTables)))) debugPredAltpred;
        return find_pred_altpred;
    endmethod

    method Action debugAllocate(Addr pc, Bit#(TLog#(numTables)) tableNum);
        ChosenTaggedTables tab = taggedTablesVector[tableNum];
        `CASE_ALL_TABLES(tab, (*/ t.allocateEntry(pc, False); /*))
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