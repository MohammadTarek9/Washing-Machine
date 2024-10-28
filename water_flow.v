module WaterFlowMonitor (
    input wire clk,                    // System clock
    input wire reset,                  // Reset signal
    input wire [9:0] water_level_sensor,  // Water level sensor input
    input wire mode,                   // Mode: 1 for filling, 0 for draining
    output reg error_flag              // Error flag output
);

    // Parameters for threshold and time limit
    parameter integer THRESHOLD = 10;     // Minimum level change required
    parameter integer TIME_LIMIT = 1000;  // Number of cycles to wait for change

    // Internal registers
    reg [9:0] previous_level;             // Stores previous water level
    reg [31:0] counter;                   // Counter for time limit

    // Process block
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset all registers and flag
            previous_level <= water_level_sensor;
            counter <= 0;
            error_flag <= 0;
        end else begin
            if (mode) begin
                // Filling mode: Expect an increase in water level
                if (water_level_sensor > previous_level + THRESHOLD) begin
                    // Water level increased by the required threshold
                    previous_level <= water_level_sensor;
                    counter <= 0;         // Reset counter on valid increase
                    error_flag <= 0;      // Clear error flag
                end else begin
                    if (counter >= TIME_LIMIT) begin
                        // If counter exceeds time limit and no valid increase
                        error_flag <= 1;  // Set error flag
                    end else begin
                        counter <= counter + 1; // Increment counter
                    end
                end
            end else begin
                // Draining mode: Expect a decrease in water level
                if (water_level_sensor < previous_level - THRESHOLD) begin
                    // Water level decreased by the required threshold
                    previous_level <= water_level_sensor;
                    counter <= 0;         // Reset counter on valid decrease
                    error_flag <= 0;      // Clear error flag
                end else begin
                    if (counter >= TIME_LIMIT) begin
                        // If counter exceeds time limit and no valid decrease
                        error_flag <= 1;  // Set error flag
                    end else begin
                        counter <= counter + 1; // Increment counter
                    end
                end
            end
        end
    end
endmodule