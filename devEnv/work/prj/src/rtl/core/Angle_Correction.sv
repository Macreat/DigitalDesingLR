module wrap_rad_L8 (
    input wire              clk,
    input wire              rst,         // Added Reset (Active High)
    input wire              en,          // Pulse to start
    input wire signed [7:0] angle_in,    // Range -100 to 100
    output reg        [15:0] angle_out,
    output reg              ready
);

    localparam integer L = 8;
    localparam integer K = 1608;     // 2π scaled by 256

    // Internal register for calculation
    reg signed [23:0] a_calc;
    
    always @(posedge clk) begin
        if (rst) begin
            angle_out <= 0;
            ready     <= 0;
            a_calc    <= 0;
        end else begin
            ready <= 0; // Default state
            
            if (en) begin
                // Step 1: Scale input
                a_calc = angle_in <<< L;

                // Step 2: Wrap Logic
                // Range +/-100 becomes +/-25600.
                // 25600 / 1608 ~= 15.9. We need 16 iterations to be safe.
                
                // Remove positive multiples of K
                repeat (16) begin
                    if (a_calc >= K) a_calc = a_calc - K;
                end

                // Remove negative multiples (add K)
                repeat (16) begin
                    if (a_calc < 0) a_calc = a_calc + K;
                end

                // Step 3: Shift back down and Output
                // Note: The remainder is shifted back, stripping the fractional part.
                angle_out <= a_calc >>> L;
                
                ready <= 1;
            end
        end
    end

endmodule