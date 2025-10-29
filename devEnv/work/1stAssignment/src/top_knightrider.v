// Top module: connects FSM, counter, decoder to create Knight Rider effect
module top_knightrider (
    input  wire       clk,
    input  wire       arst,     // asynchronous active-high reset
    input  wire       en,       // enable counting/animation
    output wire [7:0] leds      // one-hot moving light
);
    wire       dir;
    wire [3:0] count;
    wire [2:0] pos = count[2:0];
    // Compute next direction combinationally to avoid boundary dwell
    wire       dir_next = dir ? ((pos == 3'd7) ? 1'b0 : 1'b1)
                              : ((pos == 3'd0) ? 1'b1 : 1'b0);
    wire       en_cnt = en; // no gating needed with dir_next

    // Direction FSM toggles at boundaries (0 and 7)
    two_state_fsm u_fsm (
        .clk (clk),
        .arst(arst),
        .pos (pos),
        .dir (dir)
    );

    // Counter uses dir; with FSM policy it never steps outside 0..7
    updown_counter4 u_cnt (
        .clk (clk),
        .arst(arst),
        .en  (en_cnt),
        .dir (dir_next),
        .q   (count)
    );

    // 3-to-8 decoder generates one-hot LEDs
    decoder3to8 u_dec (
        .sel(pos),
        .y  (leds)
    );
endmodule
