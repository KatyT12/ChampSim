import PredImpl::*;
import BrPred::*;

export mkDirPredictor;
export DirPredTrainInfo(..);

typedef TourTrainInfo DirPredTrainInfo;

module mkDirPredictor(DirPredictor#(DirPredTrainInfo));
    let m <- mkPredImpl;
    return m;
endmodule