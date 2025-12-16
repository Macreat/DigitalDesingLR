`timescale 1ns / 1ps
module fm_synth #(
    parameter integer PHASE_WIDTH    = 32,
    parameter integer LUT_ADDR_WIDTH = 8,
    parameter integer DATA_WIDTH     = 16
) (
    input  wire                       clk,
    input  wire                       rst,
    input  wire                       gate,
    input  wire [PHASE_WIDTH-1:0]     phase_inc_base,
    input  wire [PHASE_WIDTH-1:0]     phase_inc_mod,
    input  wire signed [DATA_WIDTH-1:0] beta,
    input  wire signed [DATA_WIDTH-1:0] feedback,
    input  wire [DATA_WIDTH-1:0]      gain,
    input  wire [DATA_WIDTH-1:0]      attack_rate,
    input  wire [DATA_WIDTH-1:0]      decay_rate,
    input  wire [DATA_WIDTH-1:0]      sustain_level,
    output reg  signed [DATA_WIDTH-1:0] sample,
    output reg                        sample_valid
);

    wire [PHASE_WIDTH-1:0] carrier_phase;
    wire [PHASE_WIDTH-1:0] mod_phase;
    wire carrier_tick;
    wire mod_tick;

    phase_accumulator #(
        .PHASE_WIDTH(PHASE_WIDTH)
    ) carrier_dds (
        .phase_inc(phase_inc_base),
        .clk      (clk),
        .rst      (rst),
        .phase    (carrier_phase),
        .tick     (carrier_tick)
    );

    phase_accumulator #(
        .PHASE_WIDTH(PHASE_WIDTH)
    ) mod_dds (
        .phase_inc(phase_inc_mod),
        .clk      (clk),
        .rst      (rst),
        .phase    (mod_phase),
        .tick     (mod_tick)
    );

    wire [LUT_ADDR_WIDTH-1:0] mod_addr    = mod_phase[PHASE_WIDTH-1 -: LUT_ADDR_WIDTH];
    wire [LUT_ADDR_WIDTH-1:0] carrier_addr;

    wire signed [DATA_WIDTH-1:0] mod_sine;
    wire signed [DATA_WIDTH-1:0] carrier_sine;

    sine_lut #(
        .ADDR_WIDTH(LUT_ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) mod_lut (
        .addr   (mod_addr),
        .sample (mod_sine)
    );

    sine_lut #(
        .ADDR_WIDTH(LUT_ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) carrier_lut (
        .addr   (carrier_addr),
        .sample (carrier_sine)
    );

    reg signed [DATA_WIDTH-1:0] last_sample;

    wire signed [(2*DATA_WIDTH)-1:0] mod_mult = mod_sine * beta;
    wire signed [(2*DATA_WIDTH)-1:0] fb_mult  = last_sample * feedback;

    wire signed [DATA_WIDTH-1:0] mod_scaled = mod_mult >>> (DATA_WIDTH-2);
    wire signed [DATA_WIDTH-1:0] fb_scaled  = fb_mult  >>> (DATA_WIDTH-2);
    wire signed [DATA_WIDTH-1:0] mod_signal = mod_scaled + fb_scaled;

    localparam integer SHIFT_AMT = (PHASE_WIDTH > DATA_WIDTH) ? (PHASE_WIDTH - DATA_WIDTH) : 0;
    wire signed [PHASE_WIDTH-1:0] phase_offset =
        ({{(PHASE_WIDTH-DATA_WIDTH){mod_signal[DATA_WIDTH-1]}}, mod_signal}) << SHIFT_AMT;
    wire [PHASE_WIDTH-1:0] final_phase = carrier_phase + phase_offset;

    assign carrier_addr = final_phase[PHASE_WIDTH-1 -: LUT_ADDR_WIDTH];

    wire [DATA_WIDTH-1:0] env_level;

    envelope_gen #(
        .DATA_WIDTH(DATA_WIDTH)
    ) env (
        .clk          (clk),
        .rst          (rst),
        .gate         (gate),
        .attack_rate  (attack_rate),
        .decay_rate   (decay_rate),
        .sustain_level(sustain_level),
        .env_level    (env_level)
    );

    wire signed [DATA_WIDTH-1:0] env_level_signed = env_level;
    wire signed [DATA_WIDTH-1:0] gain_signed      = gain;

    wire signed [(2*DATA_WIDTH)-1:0] env_mult = carrier_sine * env_level_signed;
    wire signed [DATA_WIDTH-1:0] env_applied = env_mult >>> (DATA_WIDTH-2);

    wire signed [(2*DATA_WIDTH)-1:0] gain_mult = env_applied * gain_signed;
    wire signed [DATA_WIDTH-1:0] scaled_output = gain_mult >>> (DATA_WIDTH-2);

    always @(posedge clk) begin
        if (rst) begin
            sample       <= {DATA_WIDTH{1'b0}};
            sample_valid <= 1'b0;
            last_sample  <= {DATA_WIDTH{1'b0}};
        end else begin
            sample       <= scaled_output;
            sample_valid <= 1'b1;
            last_sample  <= scaled_output;
        end
    end
endmodule
