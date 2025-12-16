/* verilator lint_off UNUSEDSIGNAL */
module tb_wavegen;

  bit clk;
  bit [15:0] angle;
  bit [15:0] angle2;
  bit en;
  bit signed [15:0] wave;
  bit signed [15:0] wave2;
  bit ready;

  sine_wave_gen dut (
                  .clk(clk),
                  .angle(angle),
                  .en(en),
                  .wave(wave),
                  .ready(ready)
                );

  sine_wave_gen dut2 (
                  .clk(clk),
                  .angle(angle2),
                  .en(en),
                  .wave(wave2),
                  .ready(ready)
                );

  initial
  begin
    clk = 0;
    forever
      #5 clk = ~clk;
  end

  assign angle2 = 16'(10*angle + 5*wave);

  initial
  begin
    $dumpfile("waveform.vcd");
    $dumpvars(0, tb_wavegen);

    en = 1;
    angle = 0;
    #100;
    // Simple test sequence
    for (int i = 0; i < 120000; i++)
    begin
      angle += 1;
      #10;
    end

    $finish;
  end

endmodule
