// Simple global history
// No speculative recovery or anything
import BranchParams::*;
import Vector::*;
import ConfigReg::*;
import Ehr::*;

interface RecoverMechanism#(numeric type length);
    method ActionValue#(Bit#(length)) undo;
endinterface

interface GlobalBranchHistory#(numeric type length);
    method Bit#(length) history;
    method Bit#(length) recoveredHistory;
    method Action addHistory(Bit#(1) taken);
    interface Vector#(MaxSpecSize, RecoverMechanism#(length)) recoverFrom;
    `ifdef DEBUG
    method Action debugInitialise(Bit#(length) newHistory);
    `endif
endinterface

module mkGlobalBranchHistory(GlobalBranchHistory#(length));
    Ehr#(2, Bit#(length)) shift_register <- mkEhr(0);
    Reg#(Bit#(MaxSpecSize)) last_removed_history <- mkReg(0);
    
    Vector#(MaxSpecSize, RecoverMechanism#(length)) recoverIfc;

    for(Integer i = 0; i < valueOf(MaxSpecSize); i = i+1) begin
        recoverIfc[i] = (interface RecoverMechanism#(length);
            method ActionValue#(Bit#(length)) undo;
                Bit#(length) recovered = last_removed_history[i:0] << (valueOf(length)-i-1) | truncateLSB(shift_register[0] >> (i+1));
                shift_register[0] <= recovered;
                return recovered;
            endmethod
        endinterface);
    end
    interface recoverFrom = recoverIfc;

    method Action addHistory(Bit#(1) taken);
        shift_register[1] <= truncateLSB({shift_register[1], taken} << 1);
        last_removed_history <= truncateLSB({last_removed_history, shift_register[1][valueOf(length)-1]} << 1);
    endmethod

    method history = shift_register[0];
    method recoveredHistory = shift_register[1];

    `ifdef DEBUG
        method Action debugInitialise(Bit#(length) newHistory);
            shift_register[0] <= newHistory;
        endmethod
    `endif
endmodule