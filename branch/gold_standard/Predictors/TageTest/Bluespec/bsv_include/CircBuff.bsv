import BranchParams::*;
import BrPred::*;
import Ehr::*;

import Vector::*;

typedef Bit#(TLog#(sz)) CircBuffIndex#(numeric type sz);

interface CircBuffAssign#(numeric type size);
    method ActionValue#(CircBuffIndex#(size)) specAssign;
endinterface

interface CircBuff#(numeric type size, type t);
    interface Vector#(SupSize, CircBuffAssign#(size)) specAssign;
    // Seperate actions so only slow for updates after a misprediction? critical path?
    method Action enqueue(t data, CircBuffIndex#(size) index);
    method ActionValue#(Bit#(TAdd#(TLog#(size),1))) handleMispred(CircBuffIndex#(size) index);

    method ActionValue#(Maybe#(t)) retrieveNext;
endinterface

module mkCircBuff(CircBuff#(size, t)) provisos(Bits#(t, a__));

    // Really only an Ehr 2 is necessary but to avoid conflicts in the assingIfc it is this
    Vector#(size, Ehr#(TAdd#(SupSize,2),Maybe#(t))) buff <- replicateM(mkEhr(tagged Invalid));
    
    Reg#(CircBuffIndex#(size)) startSpec <- mkReg(0);
    
    // For now - allow for multiple predictions in a cycle
    Ehr#(TAdd#(SupSize,1), CircBuffIndex#(size)) endSpec <- mkEhr(0);

    function CircBuffIndex#(size) nextIndex(CircBuffIndex#(size) ind);
        return ind == fromInteger(valueOf(size)-1) ? 0 : ind + 1;
    endfunction

    // Methods should not conflict as the indices for update and predict theoretically should not overlap

    // Up to SupSize calls of this method in a cycle (As there are up to SupSize predictions)
    Vector#(SupSize, CircBuffAssign#(size)) assignIfc;
    for(Integer i=0; i < valueOf(SupSize); i=i+1) begin
        assignIfc[i] = (interface CircBuffAssign#(size);
        
        method ActionValue#(CircBuffIndex#(size)) specAssign;
            endSpec[i] <= nextIndex(endSpec[i]);
            buff[endSpec[i]][i] <= tagged Invalid;
            return endSpec[i];
        endmethod
        endinterface);
    end
    interface specAssign = assignIfc;
    
    // Assuming that after a misprediction is registered I will not recieve updates from branches speculated from it
    // Even if the misprediciton itself was from a mispeculated branch
    // I believe this is true
    method Action enqueue(t data, CircBuffIndex#(size) index);
        `ifdef DEBUG
            $display("Enqueing %d as %d\n", data, index);
        `endif

        buff[index][valueOf(SupSize)] <= tagged Valid data;
    endmethod

    // Index should always be == startSpec, but I seperate the methods here
    method ActionValue#(Bit#(TAdd#(TLog#(size),1))) handleMispred(CircBuffIndex#(size) index);
        endSpec[valueOf(SupSize)] <= nextIndex(index);
        
        
        Bit#(TAdd#(TLog#(size),1)) p2 = {0, endSpec[valueOf(SupSize)]};
        Bit#(TAdd#(TLog#(size),1)) ind = {0,index};

        // Might depend if predictions are clobbered if update in the same cycle
        let recoverBy = ind < p2 ? p2 - ind : p2 + (fromInteger(valueOf(size)) - ind);
        `ifdef DEBUG   
            $display("Mispredict on %d, p1=%d, p2=%d\n", index, startSpec, endSpec[valueOf(SupSize)]);
            $display("recovered history by %d bits\n", recoverBy);
        `endif
        return recoverBy;
    endmethod
    
    method ActionValue#(Maybe#(t)) retrieveNext;
        if(startSpec != endSpec[valueOf(SupSize)] &&& buff[startSpec][valueOf(SupSize)+1] matches tagged Valid .data) begin
            `ifdef DEBUG
            $display("Updated %d", data);
            `endif

            buff[startSpec][valueOf(SupSize)+1] <= tagged Invalid;
            startSpec <= nextIndex(startSpec);
        end
        return buff[startSpec][valueOf(SupSize)+1];
    endmethod

endmodule
