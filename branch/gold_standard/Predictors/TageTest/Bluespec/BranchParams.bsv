typedef 256 GlobalHistoryLength;
typedef 8 MaxSpecSize;

String dirGoldStandard  = "branch/gold_standard/Predictors/TageTest/Bluespec/";

`ifdef OFF_GOLD_STANDARD

String regInitFilename = "Build/regfileMemInit_8192.mem";
String regInitTaggedTableFilename = "Build/regfileMemInit_512.mem";

`else

String regInitFilename = dirGoldStandard + "Build/regfileMemInit_8192.mem";
String regInitTaggedTableFilename = dirGoldStandard + "Build/regfileMemInit_512.mem";

`endif
