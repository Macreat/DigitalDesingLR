`timescale 1ns / 1ps
module envelope_gen #(
    parameter integer DATA_WIDTH = 16
) (
    input  wire                   clk,
    input  wire                   rst,
    input  wire                   gate,
    input  wire [DATA_WIDTH-1:0]  attack_rate,
    input  wire [DATA_WIDTH-1:0]  decay_rate,
    input  wire [DATA_WIDTH-1:0]  sustain_level,
    output reg  [DATA_WIDTH-1:0]  env_level
);

    localparam [1:0] IDLE    = 2'd0;
    localparam [1:0] ATTACK  = 2'd1;
    localparam [1:0] DECAY   = 2'd2;
    localparam [1:0] RELEASE = 2'd3;

    reg [1:0] state;

    function [DATA_WIDTH-1:0] sat_add;
        input [DATA_WIDTH-1:0] a;
        input [DATA_WIDTH-1:0] b;
        reg   [DATA_WIDTH:0] sum;
        begin
            sum = a + b;
            sat_add = sum[DATA_WIDTH] ? {DATA_WIDTH{1'b1}} : sum[DATA_WIDTH-1:0];
        end
    endfunction

    function [DATA_WIDTH-1:0] sat_sub;
        input [DATA_WIDTH-1:0] a;
        input [DATA_WIDTH-1:0] b;
        begin
            sat_sub = (a > b) ? (a - b) : {DATA_WIDTH{1'b0}};
        end
    endfunction

    always @(posedge clk) begin
        if (rst) begin
            state     <= IDLE;
            env_level <= {DATA_WIDTH{1'b0}};
        end else begin
            case (state)
                IDLE: begin
                    env_level <= {DATA_WIDTH{1'b0}};
                    if (gate) state <= ATTACK;
                end

                ATTACK: begin
                    env_level <= sat_add(env_level, attack_rate);
                    if (env_level == {DATA_WIDTH{1'b1}}) begin
                        state <= DECAY;
                    end
                    if (~gate) state <= RELEASE;
                end

                DECAY: begin
                    if (env_level > sustain_level) begin
                        env_level <= sat_sub(env_level, decay_rate);
                    end else begin
                        env_level <= sustain_level;
                        if (~gate) state <= RELEASE;
                    end
                end

                RELEASE: begin
                    env_level <= sat_sub(env_level, decay_rate);
                    if (env_level == {DATA_WIDTH{1'b0}}) begin
                        state <= gate ? ATTACK : IDLE;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end
endmodule
