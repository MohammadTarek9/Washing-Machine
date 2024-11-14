module spin_speed_incrementor_lut(
    input clk,                           // Clock input
    input reset,                         // Reset input to initialize index
    input [2:0] wash_mode,               // Input for wash mode selection
    input increment,                     // Input signal to trigger index increment
    output reg [10:0] selected_spin_speed // Output for selected spin speed
);

    // Parameters for spin speeds
    parameter [10:0] SPEED_400  = 11'd400;
    parameter [10:0] SPEED_800  = 11'd800;
    parameter [10:0] SPEED_1200 = 11'd1200;
    parameter [10:0] SPEED_1400 = 11'd1400;

    // Variables
    reg [1:0] index;                     // Holds the mapped index for the current wash mode
    reg increment_prev;                  // To detect positive edge of increment

    // Edge detection and index increment
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Initialize index based on the wash_mode
            case (wash_mode)
                4'd0: index <= 2'd3; // COTTON -> 1400
                4'd1: index <= 2'd3; // SYNTHETICS -> 1400
                4'd2: index <= 2'd2; // DRUM_CLEAN -> 1200
                4'd3: index <= 2'd1; // QUICK_WASH -> 800
                4'd4: index <= 2'd3; // DAILY_WASH -> 1400
                4'd5: index <= 2'd0; // DELICATES -> 400
                4'd6: index <= 2'd1; // WOOL -> 800
                4'd7: index <= 2'd3; // COLOURS -> 1400
                default: index <= 2'd0;
            endcase
            increment_prev <= 0; // Initialize the previous increment signal for edge detection
        end else begin
            // Detect positive edge of increment
            if (increment && !increment_prev) begin
                // Increment index with wrap-around
                index <= (index == 2'd3) ? 2'd0 : index + 1;
            end
            increment_prev <= increment;
        end
    end

    // Assign the selected spin speed based on the current index
    always @(*) begin
        case (index)
            2'd0: selected_spin_speed = SPEED_400;
            2'd1: selected_spin_speed = SPEED_800;
            2'd2: selected_spin_speed = SPEED_1200;
            2'd3: selected_spin_speed = SPEED_1400;
            default: selected_spin_speed = SPEED_400;
        endcase
    end

endmodule