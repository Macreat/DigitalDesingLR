`timescale 1ns / 1ps
module sine_lut #(
    parameter integer ADDR_WIDTH = 8,
    parameter integer DATA_WIDTH = 16,
    parameter string  MEM_FILE   = "sim/sine_lut_q12.mem"
) (
    input  wire [ADDR_WIDTH-1:0]  addr,
    output reg  signed [DATA_WIDTH-1:0] sample
);

    localparam integer DEPTH = 1 << ADDR_WIDTH;

    reg signed [DATA_WIDTH-1:0] rom [0:DEPTH-1];

    initial begin
        $readmemh(MEM_FILE, rom);
    end

    always @(*) begin
        sample = rom[addr];
    end
endmodule
