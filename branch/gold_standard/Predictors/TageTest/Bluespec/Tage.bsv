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

`define WRAP_CODE(body) \
    let a <- action body; endaction;

`define CASE_ALL_TABLES(varName, body) \
    case (varName) matches \
    tagged T_9_9_5 .t : begin  \
        `WRAP_CODE(body) \
    end \
    tagged T_9_9_9 .t : begin \
        `WRAP_CODE(body) \
    end \
    tagged T_9_10_15 .t : begin \
        `WRAP_CODE(body) \
    end \
    tagged T_9_10_25 .t : begin \
        `WRAP_CODE(body) \
    end \
    tagged T_9_11_44 .t : begin \
        `WRAP_CODE(body) \
    end \
    tagged T_9_11_76 .t : begin \
        `WRAP_CODE(body) \
    end \
    tagged T_9_12_130 .t : begin \
        `WRAP_CODE(body) \
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

interface Tage;
    interface DirPredictor#(TageTrainInfo) dirPredInterface;
    `ifdef DEBUG
     method Action debugTables(Addr pc);
    `endif
endinterface


module mkTage(Tage);
    TaggedTable#(9,9,5)     t1 <- mkTaggedTable;
    TaggedTable#(9,9,9)     t2 <- mkTaggedTable;
    TaggedTable#(9,10,15)   t3 <- mkTaggedTable;
    TaggedTable#(9,10,25)   t4 <- mkTaggedTable;
    TaggedTable#(9,11,44)   t5 <- mkTaggedTable;
    TaggedTable#(9,11,76)   t6 <- mkTaggedTable;
    TaggedTable#(9,12,130)  t7 <- mkTaggedTable;

    //ChosenTaggedTables a <- T_9_9_5(mkTaggedTable);
    //Vector#(1, ChosenTaggedTables) taggedTablesVector = cons(T_9_9_5(mkTaggedTable), nil);
    Vector#(7, ChosenTaggedTables) taggedTablesVector = cons(T_9_9_5(t1), cons(T_9_9_9(t2), cons(T_9_10_15(t3), cons(T_9_10_25(t4), cons(T_9_11_44(t5), cons(T_9_11_76(t6), cons(T_9_12_130(t7), nil)))))));
    Reg#(Addr) currentPc <- mkRegU;

    Vector#(SupSize, DirPred#(TageTrainInfo)) predIfc;
    for(Integer i=0; i < valueOf(SupSize); i=i+1) begin
        predIfc[i] = (interface DirPred;
        method ActionValue#(DirPredResult#(TageTrainInfo)) pred;
           
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

    method Action debugTables(Addr pc);
        
        for(Integer i = 0; i < 7; i=i+1) begin
            ChosenTaggedTables tab = taggedTablesVector[i];
           
            
            `CASE_ALL_TABLES(tab, (action match {.c, .d} = t.trainingInfo(pc); $display("%d %d\n", c, d); endaction))
        
            //let a <- action (action $display("Yo\n"); $display("HI\n"); endaction); endaction;
            
            //match {.a, .b} = taggedTablesVector[i].trainingInfo(pc);
            
        end
    endmethod

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