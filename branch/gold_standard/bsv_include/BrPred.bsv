// Copyright (c) 2017 Massachusetts Institute of Technology
// 
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use, copy,
// modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
// ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Types::*;
import Vector::*;

typedef struct {
    Bool taken;
    trainInfoT train; // info that a branch must keep for future training
} DirPredResult#(type trainInfoT) deriving(Bits, Eq, FShow);

interface DirPred#(type trainInfoT);
    method ActionValue#(DirPredResult#(trainInfoT)) pred;
endinterface

function Addr offsetPc(Addr pc, Integer i) = {truncateLSB(pc), pc[7:0] + (fromInteger(i)*4)};

interface DirPredictor#(type trainInfoT);
    method Action nextPc(Addr nextPc);
    interface Vector#(SupSize, DirPred#(trainInfoT)) pred;
    method Action update(Bool taken, trainInfoT train, Bool mispred);
    method Action flush;
    method Bool flush_done;
endinterface
