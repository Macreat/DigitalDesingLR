IVERILOG ?= iverilog
VVP ?= vvp
GTKWAVE ?= gtkwave
IVERILOG_FLAGS ?= -g2012 -Wall -I src/rtl

TB ?= tb/nexys_audio_top_tb.v
TB_NAME := $(notdir $(basename $(TB)))
SIM_BUILD_DIR := sim/build
SIM_EXE := $(SIM_BUILD_DIR)/$(TB_NAME).vvp
VCD_FILE := $(SIM_BUILD_DIR)/$(TB_NAME).vcd

RTL_SRCS := $(shell find src/rtl -type f -name '*.v')

.PHONY: run waves lint clean tree

run: $(SIM_EXE)
	$(VVP) $(SIM_EXE)

$(SIM_EXE): $(TB) $(RTL_SRCS) sim/filelist.f | $(SIM_BUILD_DIR)
	$(IVERILOG) $(IVERILOG_FLAGS) -o $(SIM_EXE) -f sim/filelist.f $(TB)

$(SIM_BUILD_DIR):
	mkdir -p $(SIM_BUILD_DIR)

waves: run
	$(GTKWAVE) $(VCD_FILE) &

lint:
	verilator --lint-only -Wall -Wno-fatal -I src/rtl $(RTL_SRCS)

clean:
	rm -rf $(SIM_BUILD_DIR)

tree:
	tree -I '$(SIM_BUILD_DIR)'
