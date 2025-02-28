
# Directory containing the Bluespec Training distribution directory

TOPDIR ?= .
BSV_SRC = $(TOPDIR)/bsv_src
BSV_INCLUDE = $(TOPDIR)/bsv_include
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
PREDICTOR_INCLUDE_DIR ?= $(PRED_DIR)/$(PREDICTOR)/Bluespec/bsv_include

BSC_PATHS = -p $(BSV_SRC):$(BSV_INCLUDE):$(PRED_DIR)/$(PREDICTOR)/Bluespec:$(PREDICTOR_INCLUDE_DIR):$(PL)

TOP_BSV_PREDICTOR_FILE ?= $(TOPDIR)/$(PRED_DIR)/$(PREDICTOR)/Bluespec/$(PREDICTOR).bsv
DIR_PREDICTOR_INTERFACE_LOCATION ?= $(BSV_INCLUDE)/Predictor.bsv


GOLD_STANDARD_HEADER ?= $(INCLUDE)/gold_standard.hpp
TOP_FRAMEWORK_FILE ?= $(TOPDIR)/gold_standard.cc
INCLUDE_GOLD_STANDARD ?= $(PRED_DIR)/$(PREDICTOR)/Model/$(PREDICTOR).hpp


ifdef DEBUG_ON
	DEBUG_MACRO ?= DEBUG_DATA
else
	DEBUG_MACRO ?= NONE
endif

BSIM_DIRS = -simdir $(SIM_DIR) -bdir $(SIM_DIR) -info-dir $(SIM_DIR)
CFILE = $(BSV_SRC)/reciever.c
BSIM_EXE = $(BUILD_DIR)/$(TOPMODULE)_bsim

.PHONY: failure_check
failure_check:
	make all_bsim PREDICTOR=$(PREDICTOR) || make unset PREDICTOR=$(PREDICTOR)


ifdef MODEL_OFF
.PHONY: all_bsim
all_bsim: full_clean turn_model_checking_off set_bsv_predictor compile  link unset
else
.PHONY: all_bsim
all_bsim: full_clean  set_bsv_predictor compile  link unset set_gold_standard
endif

build_bsim:
	mkdir -p $(BUILD_DIR)
	mkdir  -p $(SIM_DIR)

.PHONY: compile
compile: build_bsim
	@echo Compiling for Bluesim ...
	bsc -u -sim -D $(DEBUG_MACRO) $(BSIM_DIRS) $(BSC_COMP_FLAGS) $(BSC_PATHS)  -g $(TOPMODULE)  $(TOPFILE)
	@echo Compiling for Bluesim finished

.PHONY: link
link:
	@echo Linking for Bluesim ...
	bsc  -I $(INCLUDE) -e $(TOPMODULE) -sim -o $(BSIM_EXE) $(BSIM_DIRS) $(BSC_LINK_FLAGS) $(BSC_PATHS) \
		$(CFILE)
	@echo Linking for Bluesim finished

.PHONY: set_gold_standard
set_gold_standard:
	test -f $(TOP_FRAMEWORK_FILE) && test -f $(INCLUDE_GOLD_STANDARD) && \
		sed -i '1s|.*|#include "$(INCLUDE_GOLD_STANDARD)"|' $(TOP_FRAMEWORK_FILE)
	test -f $(GOLD_STANDARD_HEADER) && \
		sed -i '1s|.*|#define $(DEBUG_MACRO)|' $(GOLD_STANDARD_HEADER)

turn_model_checking_off:
	test -f $(TOP_FRAMEWORK_FILE) &&\
		sed -i '1s|.*|#define MODEL_OFF|' $(TOP_FRAMEWORK_FILE)

.PHONY: set_bsv_predictor
set_bsv_predictor:
		test -f $(DIR_PREDICTOR_INTERFACE_LOCATION) && test -f $(TOP_BSV_PREDICTOR_FILE) && \
		sed -i 's/\*TO_SUBSTITUTE_FILE\*/$(PREDICTOR)/g' $(DIR_PREDICTOR_INTERFACE_LOCATION) && \
		sed -i 's/\*TO_SUBSTITUTE_MODULE\*/mk$(PREDICTOR)/g' $(DIR_PREDICTOR_INTERFACE_LOCATION)
		
.PHONY: unset
unset:
	test -f $(DIR_PREDICTOR_INTERFACE_LOCATION) && test -f $(TOP_BSV_PREDICTOR_FILE) && \
	sed -i 's/mk$(PREDICTOR)/\*TO_SUBSTITUTE_MODULE\*/g' $(DIR_PREDICTOR_INTERFACE_LOCATION) && \
	sed -i 's/$(PREDICTOR)/\*TO_SUBSTITUTE_FILE\*/g' $(DIR_PREDICTOR_INTERFACE_LOCATION)
	

.PHONY: default
default:
	failure_check

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