module temperature_incrementor_lut(
    input clk,                           // Clock input
    input reset,                         // Reset input to initialize `index`
    input [3:0] wash_mode,               // Input for wash mode selection
    input increment,                     // Input signal to trigger index increment
    output reg [6:0] selected_temperature // Output for selected temperature
);

    // Unique temperatures (distinct values only)
    reg [6:0] unique_temperatures [0:3]; // Only unique temperatures here
    reg [1:0] mode_to_temp_index [0:7];  // Array to map wash mode to index in unique_temperatures

    // Variables
    reg [1:0] index;                     // Holds the mapped index for the current wash mode
    reg increment_prev;                  // To detect positive edge of `increment`

    // Initialize the lookup tables without using an initial block
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Initialize unique temperature values and mode-to-index mapping on reset
            unique_temperatures[0] <= 7'd10;
            unique_temperatures[1] <= 7'd30;
            unique_temperatures[2] <= 7'd40;
            unique_temperatures[3] <= 7'd60;

            mode_to_temp_index[0] <= 2'd2; // COTTON -> 40
            mode_to_temp_index[1] <= 2'd2; // SYNTHETICS -> 40
            mode_to_temp_index[2] <= 2'd3; // DRUM_CLEAN -> 60
            mode_to_temp_index[3] <= 2'd0; // QUICK_WASH -> 10
            mode_to_temp_index[4] <= 2'd2; // DAILY_WASH -> 40
            mode_to_temp_index[5] <= 2'd1; // DELICATES -> 30
            mode_to_temp_index[6] <= 2'd2; // WOOL -> 40
            mode_to_temp_index[7] <= 2'd2; // COLOURS -> 40
            
            // Initialize index based on the wash_mode
            index <= mode_to_temp_index[wash_mode];
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

    // Assign the selected temperature based on the current index
    always @(*) begin
        selected_temperature = unique_temperatures[index];
    end

endmodule