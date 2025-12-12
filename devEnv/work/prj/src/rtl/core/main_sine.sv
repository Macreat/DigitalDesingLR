module main_sine (
    input  wire        clk,      // System Clock (125 MHz)
    input  wire        rst,      // Reset
    
    // --- User Inputs ---
    input  wire [8:0]  Fm,       // Modulating Frequency (9 bits)
    input  wire [12:0] Fc,       // Carrier Frequency (13 bits)
    input  wire [7:0]  Beta,     // Modulation Index (8 bits)
    
    // --- Output ---
    output wire signed [15:0] out // Final FM Audio Output
);

    // -----------------------------------------------------------------
    // STEP 2: Clock Divider (125 MHz -> ~65536 Hz)
    // -----------------------------------------------------------------
    reg [10:0] div_cnt;
    reg        clk1;

    always @(posedge clk) begin
        if (rst) begin
            div_cnt <= 0;
            clk1    <= 0;
        end else begin
            if (div_cnt >= 1906) begin
                div_cnt <= 0;
            end else begin
                div_cnt <= div_cnt + 1;
            end
            if (div_cnt < 953) clk1 <= 1; else clk1 <= 0;
        end
    end

    // -----------------------------------------------------------------
    // STEP 3: Accumulator for Modulating Signal (Fm)
    // -----------------------------------------------------------------
    wire [15:0] fm_phase_out;

    acumulador_msb acc_fm (
        .clk   (clk1),
        .rst   (rst),
        .f     (Fm),
        .q_out (fm_phase_out)
    );

    // -----------------------------------------------------------------
    // STEP 4: Sine Generator (Modulator) & Register Capture
    // -----------------------------------------------------------------
    wire        mod_ready;
    wire [15:0] mod_wave_wire;
    reg  signed [15:0] mod_sine_reg;

    sine_wave_gen sine_fm (
        .clk    (clk1),
        .enable (1'b1),
        .angle  (fm_phase_out),
        .ready  (mod_ready),
        .wave   (mod_wave_wire)
    );

    always @(posedge clk1) begin
        if (rst) begin
            mod_sine_reg <= 0;
        end else if (mod_ready) begin
            mod_sine_reg <= $signed(mod_wave_wire);
        end
    end

    // -----------------------------------------------------------------
    // STEP 5: Multiplication (Beta * Modulator Sine)
    // -----------------------------------------------------------------
    wire signed [15:0] beta_mult_result;

    mul_u8_s16_shifted mult_beta (
        .u8     (Beta),
        .s16    (mod_sine_reg),
        .result (beta_mult_result)
    );

    // -----------------------------------------------------------------
    // STEP 6: Carrier Accumulator & Phase Mixer (Addition)
    // -----------------------------------------------------------------
    wire [15:0] carrier_phase;

    acumulador_msb_Fc acc_fc (
        .clk   (clk1),
        .rst   (rst),
        .f     (Fc),
        .q_out (carrier_phase)
    );

    wire signed [15:0] total_phase_comb;
    // Add Unsigned Carrier Phase + Signed Modulation
    assign total_phase_comb = $signed({1'b0, carrier_phase}) + beta_mult_result;

    // -----------------------------------------------------------------
    // STEP 7: Pipeline Register (Store the Added Phase)
    // -----------------------------------------------------------------
    reg signed [15:0] total_phase_reg;

    always @(posedge clk1) begin
        if (rst) begin
            total_phase_reg <= 0;
        end else begin
            total_phase_reg <= total_phase_comb;
        end
    end

    // -----------------------------------------------------------------
    // STEP 8: Final Sine Generator (Carrier/Output)
    // -----------------------------------------------------------------
    
    wire [15:0] final_audio_wire;
    wire        final_ready; 

    sine_wave_gen sine_out (
        .clk    (clk1),
        .enable (1'b1),
        // Connect the calculated Phase
        .angle  (total_phase_reg), 
        .ready  (final_ready),
        .wave   (final_audio_wire)
    );

    // Assign to top-level output
    assign out = final_audio_wire;

endmodule