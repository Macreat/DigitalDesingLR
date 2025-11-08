IVERILOG ?= iverilog
VVP ?= vvp
GTKWAVE ?= gtkwave
SRC_DIR := src
TB_DIR := tb

SRCS := $(SRC_DIR)/decoder3to8.v \
        $(SRC_DIR)/updown_counter4.v \
        $(SRC_DIR)/two_state_fsm.v \
        $(SRC_DIR)/top_knightrider.v

.PHONY: all clean test waves view_top

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
	mkdir -p results

clean:
	rm -rf build results

# Generate VCD waves (uses `WAVES` macro in TBs)
waves: build
	$(IVERILOG) -g2012 -DWAVES -s tb_decoder3to8      -o build/tb_decoder3to8.vvp      $(SRCS) $(TB_DIR)/tb_decoder3to8.v
	$(IVERILOG) -g2012 -DWAVES -s tb_updown_counter4  -o build/tb_updown_counter4.vvp  $(SRCS) $(TB_DIR)/tb_updown_counter4.v
	$(IVERILOG) -g2012 -DWAVES -s tb_two_state_fsm    -o build/tb_two_state_fsm.vvp    $(SRCS) $(TB_DIR)/tb_two_state_fsm.v
	$(IVERILOG) -g2012 -DWAVES -s tb_top_knightrider  -o build/tb_top_knightrider.vvp  $(SRCS) $(TB_DIR)/tb_top_knightrider.v
	$(VVP) build/tb_decoder3to8.vvp
	$(VVP) build/tb_updown_counter4.vvp
	$(VVP) build/tb_two_state_fsm.vvp
	$(VVP) build/tb_top_knightrider.vvp

# Convenience: open GTKWave on the top TB VCD (if installed)
view_top: waves
	-$(GTKWAVE) results/tb_top_knightrider.vcd
