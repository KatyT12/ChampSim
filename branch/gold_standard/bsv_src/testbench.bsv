import StmtFSM::*;
import BrPred::*;
import Predictor::*;

// This is not very extensible at all, also might be better to just have a big blob be sent over
import "BDPI" function Action branch_pred_resp_with_debug(Bit#(8) taken, Address ip, Bit#(64) entryNumber, Bit#(64) entryValues, Bit#(128) history);

import "BDPI" function Action branch_pred_resp(Bit#(8) taken, Address ip);
import "BDPI" function ActionValue#(Bit#(160)) recieve();
import "BDPI" function Action set_file_descriptors;
import "BDPI" function Action debug;

typedef UInt#(64) Address;

typedef struct {
    UInt#(64) ip;
    UInt#(64) target;
    UInt#(8) taken;
    UInt#(8) branch_type;
} BranchUpdateInfo deriving(Bits, Eq, FShow);

typedef union tagged{
  BranchUpdateInfo UpdateReq;
  Address PredictReq;
} Message deriving(Bits, Eq, FShow);

(* synthesize *)
module mkTestbench(Empty);
    

    Reg#(Bit#(8)) prediction <- mkReg(0);
    Reg#(Message) message <- mkReg(?);
    Reg#(Bool) debug <- mkReg(?);
    let predictor <- mkDirPredictor;
    
    Reg#(DirPredResult#(DirPredTrainInfo)) pendingTrainInfo <- mkReg(DirPredResult{taken: False, train: ?});
    Reg#(DebugData) debugData <- mkReg(?);
      
    function Action test(DebugData d);
      $display("%d \n",fromMaybe(0,d.entryNumber));
    endfunction
    
    function Action predict(Address ip);
      `ifdef DEBUG_DATA
        //DirPredResultWithDebugData result = predictor.pred[0].pred;
        //test(result.debugData);
        action let a <- predictor.pred[0].pred; pendingTrainInfo <= a.predResult; debugData <= a.debugData; endaction
      `else
        action let a <- predictor.pred[0].pred; pendingTrainInfo <= a; endaction
      `endif
    endfunction

    function Action update(BranchUpdateInfo updateInfo);
      // Forces in order updates pretty much
      let branch_taken = updateInfo.taken == 1;
      return predictor.update(branch_taken, pendingTrainInfo.train, branch_taken != pendingTrainInfo.taken);
    endfunction

    function BranchUpdateInfo convertUpdate(Bit#(160) b);
      UInt#(64) ip = unpack(b[65:2]);
      UInt#(64) target = unpack(b[129:66]);
      UInt#(8) taken = unpack(b[137:130]);
      UInt#(8) branch_type = unpack(b[145:138]);
      return BranchUpdateInfo{ip: ip, target: target, taken: taken, branch_type: branch_type};
    endfunction

    function Message convertToMessage(Bit#(160) m);
      UInt#(2) t = unpack(m[1:0]);
      Message ret;
      if (t == fromInteger(1)) begin 
        ret = PredictReq(unpack(m[65:2]));
      end
      else  begin
        ret = UpdateReq(convertUpdate(m));
      end
      return ret;
    endfunction

    function Action debugUpdate(BranchUpdateInfo b);
      $display("BSV Update IP: %d, target : %d, taken: %d, Type %d:", b.ip, b.target, b.taken, b.branch_type);
    endfunction

    function Action debugPredictionReq(Address ip);
      $display("BSV Predict IP: %d", ip);
    endfunction

    function Bool isPred(Message m);
      Bool x = False;
      case(m) matches
        tagged PredictReq .pr : x = True;
      endcase
      return x;
    endfunction

    //Reg#(BranchUpdateInfo) update <- mkReg(?);


    Stmt stmt = seq 
        set_file_descriptors;
        action let a <- $test$plusargs("DEBUG"); debug <= a; endaction
            while(True) seq
              action let a <- recieve; message <= convertToMessage(a); endaction
              if (isPred(message)) seq
                predictor.nextPc(pack(message.PredictReq));
                predict(message.PredictReq);
                if(debug) debugPredictionReq(message.PredictReq);
                `ifdef DEBUG_DATA
                  branch_pred_resp_with_debug({7'b0000000,pack(pendingTrainInfo.taken)}, message.PredictReq, fromMaybe(0,debugData.entryNumber), fromMaybe(0,debugData.entryValues), fromMaybe(0, debugData.history));
                `else
                  branch_pred_resp({7'b0000000,pack(pendingTrainInfo.taken)}, message.PredictReq);
                `endif
              endseq
              if (!isPred(message)) seq
                update(message.UpdateReq);
                if(debug) debugUpdate(message.UpdateReq);
              endseq
            endseq
            /*while(True) seq
              action let a <- branch_update_req; update <= a; endaction  
              debugUpdate(convertUpdate(update));
            endseq*/
        //my_display(b);
    endseq;

    

  mkAutoFSM(stmt);
endmodule
