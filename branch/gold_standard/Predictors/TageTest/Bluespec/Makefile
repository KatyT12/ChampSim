
# Directory containing the Bluespec Training distribution directory

TOPDIR ?= .

TESTBENCH_PATH ?= $(TOPDIR)/test_benches
BSV_SRC = $(TOPDIR)
BSV_INCLUDE = $(TOPDIR)/bsv_include:../../../bsv_include
SIM_DIR ?= $(BUILD_DIR)/build_bsim
BUILD_DIR ?= $(TOPDIR)/Build

FILE_NAME ?= TableTestBench
TOPFILE   ?= $(TESTBENCH_PATH)/$(FILE_NAME).bsv
TOPMODULE ?= mk$(FILE_NAME)

PL = /opt/tools/bsc/latest/lib/Libraries/
BSC_COMP_FLAGS = -keep-fires -aggressive-conditions -no-warn-action-shadowing -check-assert
BSC_LINK_FLAGS = -keep-fires
BSC_PATHS = -p $(BSV_SRC):$(BSV_INCLUDE):$(PL)


BSIM_DIRS = -simdir $(SIM_DIR) -bdir $(SIM_DIR) -info-dir $(SIM_DIR)
BSIM_EXE = $(BUILD_DIR)/$(TOPMODULE)_bsim

ifdef DEBUG
	DEBUG_MACRO ?= DEBUG
else
	DEBUG_MACRO ?= NONE
endif

ifdef OFF_GOLD_STANDARD
	GOLD_STANDARD_MACRO = OFF_GOLD_STANDARD
else
	GOLD_STANDARD_MACRO = NONE
endif

all_bsim: full_clean build_bsim generate_mem_files compile  link simulate



MEM_BASE_NAME = regfileMemInit
MEM_FILE_SIZES = 512:0 8192:1 2048:0

generate_mem_files:
	@for pair in $(MEM_FILE_SIZES); do \
			size=$$(echo $$pair | cut -d':' -f1); \
			init=$$(echo $$pair | cut -d':' -f2); \
			printf "%.0s$$init\n" $$(seq 1 $$size) > $(BUILD_DIR)/$(MEM_BASE_NAME)_$$size.mem; \
	done

build_bsim:
	mkdir -p $(BUILD_DIR)
	mkdir  -p $(SIM_DIR)

.PHONY: compile
compile:
	@echo Compiling for Bluesim ...
	bsc -u -sim -D $(DEBUG_MACRO) -D $(GOLD_STANDARD_MACRO) $(BSIM_DIRS) $(BSC_COMP_FLAGS) $(BSC_PATHS)  -g $(TOPMODULE)  $(TOPFILE)
	@echo Compiling for Bluesim finished

.PHONY: link
link:
	@echo Linking for Bluesim ...
	bsc  -e $(TOPMODULE) -sim -o $(BSIM_EXE) $(BSIM_DIRS) $(BSC_LINK_FLAGS) $(BSC_PATHS)
	@echo Linking for Bluesim finished

.PHONY: default
default:
	failure_check

.PHONY: simulate
simulate:
	@echo Bluesim simulation ...
	./$(BSIM_EXE)
	@echo Bluesim simulation finished

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