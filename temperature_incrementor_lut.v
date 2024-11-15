module temperature_incrementor_lut(
    input clk,                           // Clock input
    input reset,                         // Reset input to initialize `index`
    input [2:0] wash_mode,               // Input for wash mode selection
    input increment,                     // Input signal to trigger index increment
    output reg [6:0] selected_temperature // Output for selected temperature
);

    // Parameters for temperatures
    parameter [6:0] TEMP_10 = 7'd10;
    parameter [6:0] TEMP_30 = 7'd30;
    parameter [6:0] TEMP_40 = 7'd40;
    parameter [6:0] TEMP_60 = 7'd60;

    // Variables
    reg [1:0] index;                     // Holds the mapped index for the current wash mode
    reg increment_prev;                  // To detect positive edge of `increment`

    // Edge detection and index increment
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Initialize index based on the wash_mode
            case (wash_mode)
                3'd0: index <= 2'd2; // COTTON -> 40
                3'd1: index <= 2'd2; // SYNTHETICS -> 40
                3'd2: index <= 2'd3; // DRUM_CLEAN -> 60
                3'd3: index <= 2'd0; // QUICK_WASH -> 10
                3'd4: index <= 2'd2; // DAILY_WASH -> 40
                3'd5: index <= 2'd1; // DELICATES -> 30
                3'd6: index <= 2'd2; // WOOL -> 40
                3'd7: index <= 2'd2; // COLOURS -> 40
                default: index <= 2'd0;
            endcase
            increment_prev <= 0; // Initialize the previous increment signal for edge detection
        end else begin
            // Detect positive edge of `increment`
            if (increment && !increment_prev) begin
                // Increment `index` with wrap-around
                index <= (index == 2'd3) ? 2'd0 : index + 1;
            end
            increment_prev <= increment;
        end
    end

    // Assign the selected temperature based on the current index
    always @(*) begin
        case (index)
            2'd0: selected_temperature = TEMP_10;
            2'd1: selected_temperature = TEMP_30;
            2'd2: selected_temperature = TEMP_40;
            2'd3: selected_temperature = TEMP_60;
            default: selected_temperature = TEMP_10;
        endcase
    end
    
endmodule
