IVERILOG ?= iverilog
VVP ?= vvp
GTKWAVE ?= gtkwave
SRC_DIR := src
TB_DIR := tb

SRCS := $(SRC_DIR)/baud_gen.v \
        $(SRC_DIR)/detector.v \
        $(SRC_DIR)/sipo_reg.v \
		$(SRC_DIR)/uart_sampler.v \
        $(SRC_DIR)/top.v

.PHONY: all clean test waves view_top

all: test

build/tb_baud_gen.vvp: $(SRCS) $(TB_DIR)/tb_baud_gen.v | build
	$(IVERILOG) -g2012 -s tb_baud_gen -o $@ $^

build/tb_uart_sampler.vvp: $(SRCS) $(TB_DIR)/tb_uart_sampler.v | build
	$(IVERILOG) -g2012 -s tb_uart_sampler -o $@ $^

build/tb_sipo_reg.vvp: $(SRCS) $(TB_DIR)/tb_sipo_reg.v | build
	$(IVERILOG) -g2012 -s tb_sipo_reg -o $@ $^

build/tb_detector.vvp: $(SRCS) $(TB_DIR)/tb_detector.v | build
	$(IVERILOG) -g2012 -s tb_detector -o $@ $^

build/tb_top.vvp: $(SRCS) $(TB_DIR)/tb_top.v | build
	$(IVERILOG) -g2012 -s tb_top -o $@ $^

test: build/tb_baud_gen.vvp build/tb_uart_sampler.vvp build/tb_sipo_reg.vvp build/tb_detector.vvp build/tb_top.vvp
	$(VVP) build/tb_baud_gen.vvp
	$(VVP) build/tb_uart_sampler.vvp
	$(VVP) build/tb_sipo_reg.vvp
	$(VVP) build/tb_detector.vvp
	$(VVP) build/tb_top.vvp

build:
	mkdir -p build
	mkdir -p results

clean:

# Generate VCD waves (uses `WAVES` macro in TBs)
waves: build
	$(IVERILOG) -g2012 -DWAVES -s tb_baud_gen      -o build/tb_baud_gen.vvp      $(SRCS) $(TB_DIR)/tb_baud_gen.v
	$(IVERILOG) -g2012 -DWAVES -s tb_uart_sampler  -o build/tb_uart_sampler.vvp  $(SRCS) $(TB_DIR)/tb_uart_sampler.v
	$(IVERILOG) -g2012 -DWAVES -s tb_sipo_reg    -o build/tb_sipo_reg.vvp    $(SRCS) $(TB_DIR)/tb_sipo_reg.v
	$(IVERILOG) -g2012 -DWAVES -s tb_detector  -o build/tb_detector.vvp  $(SRCS) $(TB_DIR)/tb_detector.v
	$(IVERILOG) -g2012 -DWAVES -s tb_top  -o build/tb_top.vvp  $(SRCS) $(TB_DIR)/tb_top.v

	$(VVP) build/tb_baud_gen.vvp
	$(VVP) build/tb_uart_sampler.vvp
	$(VVP) build/tb_sipo_reg.vvp
	$(VVP) build/tb_detector.vvp
	$(VVP) build/tb_top.vvp


# Convenience: open GTKWave on the top TB VCD (if installed)
view_top: waves
	-$(GTKWAVE) results/tb_top.vcd
