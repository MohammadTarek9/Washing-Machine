module washing_machine_load_size_detection(
    input wire clk,        // Clock signal
    input wire reset,      // Reset signal
    input wire [7:0] load_weight, // Load sensor input representing the weight of clothes
    output reg [9:0] water_level  // Output representing the water level based on load weight
);

// Thresholds for load weight to determine water level
parameter LOW_THRESHOLD = 8'd20;    // 20 units of weight for Low water level
parameter MEDIUM_THRESHOLD = 8'd50; // 50 units of weight for Medium water level
parameter HIGH_THRESHOLD = 8'd80;   // 80 units of weight for High water level

// State machine to control water level
parameter LOW_SENSOR_VALUE = 10'd175;    // Sensor reading for Low water level
parameter MEDIUM_SENSOR_VALUE = 10'd300; // Sensor reading for Medium water level
parameter HIGH_SENSOR_VALUE = 10'd600;   // Sensor reading for High water level
parameter EXTRA_HIGH_SENSOR_VALUE = 10'd900; // Sensor reading for Extra High water level

// State machine to control water level based on load weight
always @(posedge clk or posedge reset) begin
    if (reset) begin
        water_level <= 10'd0; // Reset to 0 (no water level)
    end else begin
        if (load_weight <= LOW_THRESHOLD) begin
            water_level <= LOW_SENSOR_VALUE; // Low water level
        end else if (load_weight <= MEDIUM_THRESHOLD) begin
            water_level <= MEDIUM_SENSOR_VALUE; // Medium water level
        end else if (load_weight <= HIGH_THRESHOLD) begin
            water_level <= HIGH_SENSOR_VALUE; // High water level
        end else begin
            water_level <= EXTRA_HIGH_SENSOR_VALUE; // Extra High water level
        end
    end
end
//check that the water level is set to 0 when reset is high
/*
psl default clock=rose(clk);
psl property RESET_WATER_LEVEL = always (reset==1 -> next(water_level==0));
psl assert RESET_WATER_LEVEL;
*/
//check that the water level is set to LOW_SENSOR_VALUE when load_weight is less than or equal to LOW_THRESHOLD
/*
psl property LOW_WATER_LEVEL = always ((load_weight<=LOW_THRESHOLD && !reset) -> next(water_level==LOW_SENSOR_VALUE));
psl assert LOW_WATER_LEVEL;
*/
//check that the water level is set to MEDIUM_SENSOR_VALUE when load_weight is less than or equal to MEDIUM_THRESHOLD
/*
psl property MEDIUM_WATER_LEVEL = always ((load_weight<=MEDIUM_THRESHOLD && load_weight>LOW_THRESHOLD && !reset) -> next(water_level==MEDIUM_SENSOR_VALUE));
psl assert MEDIUM_WATER_LEVEL;
*/
//check that the water level is set to HIGH_SENSOR_VALUE when load_weight is less than or equal to HIGH_THRESHOLD
/*
psl property HIGH_WATER_LEVEL = always ((load_weight<=HIGH_THRESHOLD && load_weight>MEDIUM_THRESHOLD && !reset) -> next(water_level==HIGH_SENSOR_VALUE));
psl assert HIGH_WATER_LEVEL;
*/
//check that the water level is set to EXTRA_HIGH_SENSOR_VALUE when load_weight is greater than HIGH_THRESHOLD
/*
psl property EXTRA_HIGH_WATER_LEVEL = always ((load_weight>HIGH_THRESHOLD && !reset) -> next(water_level==EXTRA_HIGH_SENSOR_VALUE));
psl assert EXTRA_HIGH_WATER_LEVEL;
*/
endmodule