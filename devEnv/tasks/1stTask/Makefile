IVERILOG ?= iverilog
VVP ?= vvp
SRC_DIR := src
TB_DIR := tb

SRCS := $(SRC_DIR)/decoder3to8.v \
        $(SRC_DIR)/updown_counter4.v \
        $(SRC_DIR)/two_state_fsm.v \
        $(SRC_DIR)/top_knightrider.v

.PHONY: all clean test

all: test

build/tb_decoder3to8.vvp: $(SRCS) $(TB_DIR)/tb_decoder3to8.v | build
	$(IVERILOG) -g2012 -s tb_decoder3to8 -o $@ $^

build/tb_updown_counter4.vvp: $(SRCS) $(TB_DIR)/tb_updown_counter4.v | build
	$(IVERILOG) -g2012 -s tb_updown_counter4 -o $@ $^

build/tb_two_state_fsm.vvp: $(SRCS) $(TB_DIR)/tb_two_state_fsm.v | build
	$(IVERILOG) -g2012 -s tb_two_state_fsm -o $@ $^

build/tb_top_knightrider.vvp: $(SRCS) $(TB_DIR)/tb_top_knightrider.v | build
	$(IVERILOG) -g2012 -s tb_top_knightrider -o $@ $^

test: build/tb_decoder3to8.vvp build/tb_updown_counter4.vvp build/tb_two_state_fsm.vvp build/tb_top_knightrider.vvp
	$(VVP) build/tb_decoder3to8.vvp
	$(VVP) build/tb_updown_counter4.vvp
	$(VVP) build/tb_two_state_fsm.vvp
	$(VVP) build/tb_top_knightrider.vvp

build:
	mkdir -p build

clean:
	rm -rf build

