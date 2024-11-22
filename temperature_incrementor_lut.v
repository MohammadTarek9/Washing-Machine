module temperature_incrementor_lut(
    input clk,                           // Clock input
    input reset,                         // Reset input to initialize `index`
    input [2:0] wash_mode,               // Input for wash mode selection
    input increment,                     // Input signal to trigger index increment
    output reg [5:0] selected_temperature // Output for selected temperature
);

    // Parameters for temperatures
    parameter [5:0] TEMP_10 = 6'd10;
    parameter [5:0] TEMP_30 = 6'd30;
    parameter [5:0] TEMP_40 = 6'd40;
    parameter [5:0] TEMP_60 = 6'd60;

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
                default: index <= 2'd2; // COLOURS -> 40
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
            default: selected_temperature = TEMP_60;
        endcase
    end
//ensure that the selected temperature is correct for each wash mode when temp_reset is high
/*
psl default clock=rose(clk);
psl property TEMP_RESET_INDEX=always (reset==1 -> next((wash_mode == 3'd0 && index == 2'd2) ||
    (wash_mode == 3'd1 && index == 2'd2) ||
    (wash_mode == 3'd2 && index == 2'd3) ||
    (wash_mode == 3'd3 && index == 2'd0) ||
    (wash_mode == 3'd4 && index == 2'd2) ||
    (wash_mode == 3'd5 && index == 2'd1) ||
    (wash_mode == 3'd6 && index == 2'd2) ||
    (wash_mode == 3'd7 && index == 2'd2) || (wash_mode === 3'bx && index == 2'd0)));
    psl assert TEMP_RESET_INDEX;
*/
// ensure index wraps around correctly
/*
psl property INDEX_WRAP = always ((increment && !increment_prev && !reset && index == 2'd3) ->
    next(index == 2'd0));
psl assert INDEX_WRAP;
*/
// ensure index is incremented correctly
/*
psl property INDEX_INCREMENT = always ((increment && !increment_prev && !reset && index != 2'd3) ->
    next(index == prev(index) + 1'b1));
psl assert INDEX_INCREMENT;
*/

endmodule

