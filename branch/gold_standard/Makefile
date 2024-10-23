
# Directory containing the Bluespec Training distribution directory

TOPDIR ?= .
BSV_SRC = $(TOPDIR)/bsv_src
PRED_DIR ?= $(TOPDIR)/Predictors
BUILD_DIR ?= $(TOPDIR)/Build
SIM_DIR ?= $(BUILD_DIR)/build_bsim

# Set this to the command that invokes your Verilog simulator
# VSIM ?= iverilog
VSIM ?= cvc
# VSIM ?= cver
# VSIM ?= vcsi
# VSIM ?= vcs
# VSIM ?= modelsim
# VSIM ?= ncsim
# VSIM ?= ncverilog

# ================================================================
# You should not have to change anything below this line

TOPFILE   ?= $(BSV_SRC)/testbench.bsv
TOPMODULE ?= mkTestbench


PL = /opt/tools/bsc/latest/lib/Libraries/
BSC_COMP_FLAGS = -elab -keep-fires -aggressive-conditions -no-warn-action-shadowing
INCLUDE = $(TOPDIR)/include
BSC_LINK_FLAGS = -keep-fires
PREDICTOR ?= TourPredictor
BSC_PATHS = -p $(BSV_SRC):$(TOPDIR)/bsv_include:$(PRED_DIR)/$(PREDICTOR):$(PL)



BSIM_DIRS = -simdir $(SIM_DIR) -bdir $(SIM_DIR) -info-dir $(SIM_DIR)
CFILE = $(BSV_SRC)/reciever.c
BSIM_EXE = $(BUILD_DIR)/$(TOPMODULE)_bsim

.PHONY: all_bsim
all_bsim: full_clean  compile  link

build_bsim:
	mkdir -p $(BUILD_DIR)
	mkdir  -p $(SIM_DIR)

.PHONY: compile
compile: build_bsim
	@echo Compiling for Bluesim ...
	bsc -u -sim $(BSIM_DIRS) $(BSC_COMP_FLAGS) $(BSC_PATHS) -g $(TOPMODULE)  $(TOPFILE)
	@echo Compiling for Bluesim finished

.PHONY: link
link:
	@echo Linking for Bluesim ...
	bsc  -I $(INCLUDE) -e $(TOPMODULE) -sim -o $(BSIM_EXE) $(BSIM_DIRS) $(BSC_LINK_FLAGS) $(BSC_PATHS) \
		$(CFILE)
	@echo Linking for Bluesim finished


.PHONY: default
default:
	all_bsim

#.PHONY: simulate
#simulate:
#	@echo Bluesim simulation ...
#	./$(BSIM_EXE)
#	@echo Bluesim simulation finished

.PHONY: clean
clean:
	rm -rf $(BUILD_DIR)/*

.PHONY: full_clean
full_clean:
	rm -r -f  $(BUILD_DIR)


.PHONY: help
help:
	@echo "Current settings"
	@echo "    BLUESPEC_LICENSE_FILE = " $(BLUESPEC_LICENSE_FILE)
	@echo "    BLUESPEC_HOME         = " $(BLUESPEC_HOME)
	@echo "    BLUESPECDIR           = " $(BLUESPECDIR)
	@echo ""
	@echo ""
	@echo "Targets for 'make':"
	@echo "    help                Print this information"
	@echo ""
	@echo "    Bluesim:"
	@echo "        compile         Compile for Bluesim"
	@echo "        link            Link a Bluesim executable"
	@echo "        simulate        Run the Bluesim simulation executable"
	@echo "                            (generates VCD file; remove -V flag to suppress VCD gen)"
	@echo "        all_bsim        Convenience for make compile link simulate"
	@echo ""
	@echo "    Verilog generation and Verilog sim:"
	@echo "        verilog         Compile for Verilog (Verilog files generated in verilog_dir/)"
	@echo "        v_link          Link a Verilog simulation executable"
	@echo "                            (current simulator:" $(VSIM) " (redefine VSIM for other Verilog simulators)"
	@echo "        v_simulate      Run the Verilog simulation executable"
	@echo "        all_vsim        Convenience for make verilog v_link v_simulate"
	@echo "                            (generates VCD file; remove +bscvcd flag to suppress VCD gen)"
	@echo ""
	@echo "    clean               Delete intermediate files in build_bsim/ and build_v/ dirs"
	@echo "    full_clean          Delete all but this Makefile"