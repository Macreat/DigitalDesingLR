// Two-state FSM controlling direction based on position bounds
// States: RIGHT (dir=1), LEFT (dir=0)
module two_state_fsm (
    input  wire       clk,
    input  wire       arst,   // asynchronous active-high reset
    input  wire [2:0] pos,    // current position 0..7
    output reg        dir     // 1 = right/up, 0 = left/down
);
    localparam RIGHT = 1'b1;
    localparam LEFT  = 1'b0;

    // State register is 'dir' itself
    always @(posedge clk or posedge arst) begin
        if (arst) begin
            dir <= RIGHT; // start moving right by default
        end else begin
            case (dir)
                RIGHT: dir <= (pos == 3'd7) ? LEFT : RIGHT;
                LEFT:  dir <= (pos == 3'd0) ? RIGHT : LEFT;
                default: dir <= RIGHT;
            endcase
        end
    end
endmodule

