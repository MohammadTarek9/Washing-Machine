module spin_speed_incrementor_lut(
    input clk,                           // Clock input
    input reset,                         // Reset input to initialize `index`
    input [3:0] wash_mode,               // Input for wash mode selection
    input increment,                     // Input signal to trigger index increment
    output reg [10:0] selected_spin_speed // Output for selected spin speed
);

    // Unique spin speeds (distinct values only)
    reg [10:0] unique_spin_speeds [0:3]; // Only unique spin speeds here
    reg [1:0] mode_to_speed_index [0:7]; // Array to map wash mode to index in unique_spin_speeds

    // Variables
    reg [1:0] index;                     // Holds the mapped index for the current wash mode
    reg increment_prev;                  // To detect positive edge of `increment`

    // Initialize the lookup tables without using an initial block
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Initialize unique spin speed values and mode-to-index mapping on reset
            unique_spin_speeds[0] <= 11'd400;
            unique_spin_speeds[1] <= 11'd800;
            unique_spin_speeds[2] <= 11'd1200;
            unique_spin_speeds[3] <= 11'd1400;

            mode_to_speed_index[0] <= 2'd3; // COTTON -> 1400
            mode_to_speed_index[1] <= 2'd3; // SYNTHETICS -> 1400
            mode_to_speed_index[2] <= 2'd2; // DRUM_CLEAN -> 1200
            mode_to_speed_index[3] <= 2'd1; // QUICK_WASH -> 800
            mode_to_speed_index[4] <= 2'd3; // DAILY_WASH -> 1400
            mode_to_speed_index[5] <= 2'd0; // DELICATES -> 400
            mode_to_speed_index[6] <= 2'd1; // WOOL -> 800
            mode_to_speed_index[7] <= 2'd3; // COLOURS -> 1400
            
            // Initialize index based on the wash_mode
            index <= mode_to_speed_index[wash_mode];
            increment_prev <= 0; // Initialize the previous increment signal for edge detection
        end else begin
            // Detect positive edge of `increment`
            if (increment && !increment_prev) begin
                // Increment `index` with wrap-around after the reset initialization
                index <= (index == 3) ? 0 : index + 1;
            end

            // Update `increment_prev` to the current value of `increment` for edge detection
            increment_prev <= increment;
        end
    end

    // Assign the selected spin speed based on the current index
    always @(*) begin
        selected_spin_speed = unique_spin_speeds[index];
    end

endmodule