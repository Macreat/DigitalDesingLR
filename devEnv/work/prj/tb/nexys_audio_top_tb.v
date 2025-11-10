`timescale 1ns / 1ps

module nexys_audio_top_tb;
    localparam integer CLK_PERIOD = 10;
    localparam integer BIT_PERIOD = 32_000;

    reg clk = 1'b0;
    reg rst_n = 1'b0;
    reg midi_rx = 1'b1;
    reg gate_button = 1'b0;
    reg [3:0] user_sw = 4'b0000;

    wire audio_pwm_p;
    wire audio_pwm_n;

    always #(CLK_PERIOD/2) clk = ~clk;

    nexys_audio_top dut (
        .clk100     (clk),
        .rst_n      (rst_n),
        .midi_rx    (midi_rx),
        .gate_button(gate_button),
        .user_sw    (user_sw),
        .audio_pwm_p(audio_pwm_p),
        .audio_pwm_n(audio_pwm_n)
    );

    task send_midi(input [7:0] data);
        integer i;
        begin
            midi_rx <= 1'b0;
            #(BIT_PERIOD);
            for (i = 0; i < 8; i = i + 1) begin
                midi_rx <= data[i];
                #(BIT_PERIOD);
            end
            midi_rx <= 1'b1;
            #(BIT_PERIOD);
        end
    endtask

    initial begin
        $dumpfile("sim/build/nexys_audio_top_tb.vcd");
        $dumpvars(0, nexys_audio_top_tb);
    end

    initial begin
        #(50*CLK_PERIOD);
        rst_n <= 1'b1;
        #(50*CLK_PERIOD);

        // configure parameters via MIDI
        send_midi(8'b0010_1111); // base increment coarse
        send_midi(8'b0110_0001); // beta
        send_midi(8'b1110_0101); // gain

        gate_button <= 1'b1;
        #(10_000*CLK_PERIOD);
        gate_button <= 1'b0;
        #(5_000*CLK_PERIOD);
        user_sw[0] <= 1'b1;
        #(5_000*CLK_PERIOD);
        $finish;
    end
endmodule
