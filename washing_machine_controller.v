module washing_machine_controller (
    input clk,                   // Clock signal
    input reset,                 // Reset signal
    input start,                 // Start button
    input stop,                 // Stop button
    input [3:0] wash_mode                 //wash mode selector, see comments next to the case statement that handles these wash modes
    input [1:0] wash_cycle,      // Wash cycle selector (00 = Normal, 01 = Delicate, 10 = Heavy Duty, 11 = Quick Wash)
    input [1:0] temperature,     // Temperature selector (00 = Cold, 01 = Warm, 10 = Hot)
    input [1:0] spin_speed,      // Spin speed selector (00 = Low, 01 = Medium, 10 = High)
    input door_locked,           // Door lock sensor (1 = Locked, 0 = Unlocked)
    input [9:0] water_level_sensor,     // Water level sensor (10-bit ADC output)
    input [9:0] temperature_adc, // Temperature sensor ADC output
    input [9:0] motor_speed_sensor, // Motor speed sensor (Tachometer)
    input vibration_sensor,      // Vibration sensor (1 = Excessive vibration)
    input wire [7:0] load_weight, 

    output reg water_valve,           // Control for water valve (1 = Open, 0 = Close)
    output reg heater,                // Control for heater (1 = On, 0 = Off)
    output reg [3:0]drum_motor,            // Control for drum motor (1 = On, 0 = Off)
    output reg drain_pump,            // Control for drain pump (1 = On, 0 = Off)
    output reg door_lock,             // Control for door lock (1 = Locked, 0 = Unlocked)
    output reg cycle_complete_led,    // LED indicator for cycle complete
    output reg error_led              // LED indicator for errors
);

wire [2:0] water_level;

// Define temperatures
parameter WASH_TEMP_COLD = 10'd100;
parameter WASH_TEMP_WARM = 10'd500;
parameter WASH_TEMP_HOT = 10'd900;

// Define spin speeds
parameter SPIN_SPEED_LOW = 10'd1;
parameter SPIN_SPEED_MEDIUM = 10'd2;
parameter SPIN_SPEED_HIGH = 10'd4;

// Define wash speeds
parameter SPIN_SPEED_LOW = 10'd30;
parameter SPIN_SPEED_MEDIUM = 10'd50;
parameter SPIN_SPEED_HIGH = 10'd60;


// Arrays to store target values for each mode
reg [9:0] target_temperature_array [0:11];
reg [9:0] target_spin_speed_array [0:11];
reg [9:0] target_SPIN_SPEED_array [0:11];

// Initialize arrays
initial begin
    // Temperature settings
    target_temperature_array[0] = WASH_TEMP_WARM;   // COTTON
    target_temperature_array[1] = WASH_TEMP_WARM;   // E-COTTON
    target_temperature_array[2] = WASH_TEMP_WARM;   // SYNTHETIC
    target_temperature_array[3] = WASH_TEMP_COLD;   // WOOL
    target_temperature_array[4] = WASH_TEMP_COLD;   // DELICATE
    target_temperature_array[5] = WASH_TEMP_COLD;   // QUICK_WASH
    target_temperature_array[6] = WASH_TEMP_HOT;    // HYGIENE_STEAM
    target_temperature_array[7] = WASH_TEMP_HOT;    // DRUM_CLEAN
    target_temperature_array[8] = WASH_TEMP_COLD;   // SUPER_ECO_WASH
    target_temperature_array[9] = WASH_TEMP_COLD;   // COLOURS
    target_temperature_array[10] = WASH_TEMP_WARM;  // DAILY_WASH
    target_temperature_array[11] = WASH_TEMP_HOT;   // BEDDING


    // Wash speed settings
    target_SPIN_SPEED_array[0] = SPIN_SPEED_HIGH;    // COTTON
    target_SPIN_SPEED_array[1] = SPIN_SPEED_HIGH;    // E-COTTON
    target_SPIN_SPEED_array[2] = SPIN_SPEED_MEDIUM;  // SYNTHETIC
    target_SPIN_SPEED_array[3] = SPIN_SPEED_LOW;     // WOOL
    target_SPIN_SPEED_array[4] = SPIN_SPEED_LOW;     // DELICATE
    target_SPIN_SPEED_array[5] = SPIN_SPEED_HIGH;    // QUICK_WASH
    target_SPIN_SPEED_array[6] = SPIN_SPEED_HIGH;    // HYGIENE_STEAM
    target_SPIN_SPEED_array[7] = SPIN_SPEED_HIGH;    // DRUM_CLEAN
    target_SPIN_SPEED_array[8] = SPIN_SPEED_HIGH;    // SUPER_ECO_WASH
    target_SPIN_SPEED_array[9] = SPIN_SPEED_HIGH;    // COLOURS
    target_SPIN_SPEED_array[10] = SPIN_SPEED_HIGH;   // DAILY_WASH
    target_SPIN_SPEED_array[11] = SPIN_SPEED_HIGH;   // BEDDING
end

// State Encoding
parameter IDLE              = 4'b0000;
parameter LOCK_DOOR         = 4'b0001;
parameter FILL_INITIAL      = 4'b0010;
parameter HEAT_FILL         = 4'b0011;
parameter ADD_DETERGENT     = 4'b0100;
parameter WASH              = 4'b0101;
parameter DRAIN_AFTER_WASH  = 4'b0110;
parameter FILL_SOFTENER     = 4'b0111;
parameter RINSE             = 4'b1000;
parameter DRAIN_AFTER_RINSE = 4'b1001;
parameter DRY_SPIN          = 4'b1010;
parameter COMPLETE          = 4'b1011;

reg [3:0] current_state, next_state;

// Parameters for cycle durations, water level thresholds, and temperatures
parameter MAX_WATER_LEVEL = 10'd512;
parameter WASH_TEMP_WARM = 10'd300;
parameter WASH_TEMP_HOT  = 10'd600;
parameter MAX_SPIN_SPEED = 10'd1200;

// Registers to store the selected cycle parameters
reg [9:0] target_temperature;
reg [9:0] target_spin_speed;
reg [9:0] target_SPIN_SPEED;

parameter clk_cycle = 1; // in seconds
parameter NORMAL_SPIN_DURATION = 360 / clk_cycle;
parameter DELICATE_SPIN_DURATION = 180 / clk_cycle;
parameter HEAVY_DUTY_SPIN_DURATION = 480 / clk_cycle;
parameter QUICK_WASH_SPIN_DURATION = 240 / clk_cycle;




// FSM: Sequential block to transition between states
always @(posedge clk or posedge reset) begin
    if (reset) begin
        current_state <= IDLE;
        spin_timer <= 0;
    end else begin
        current_state <= next_state;

        // Increment spin timer if in SPIN state
        if (current_state == SPIN) begin
            spin_timer <= spin_timer + 1;
        end else begin
            spin_timer <= 0; // Reset timer when not in SPIN state
        end
    end
end

// FSM: Combinational block for determining the next state and control logic
always @(*) begin
    // Default control signals
    water_valve = 0;
    heater = 0;
    drum_motor = 0;
    drain_pump = 0;
    door_lock = 0;
    cycle_complete_led = 0;
    error_led = 0;
    
case (current_state)
        IDLE: begin
            if (start) begin
                next_state = LOCK_DOOR;
            end else begin
                next_state = IDLE;
            end
        end

        LOCK_DOOR: begin
            door_lock = 1;
            next_state = FILL_INITIAL;
        end

        FILL_INITIAL: begin
            water_valve = 1;
            if (water_level_sensor >= GENERAL_WATER_LEVEL) begin
                next_state = HEAT_FILL;
            end else begin
                next_state = FILL_INITIAL;
            end
        end

        HEAT_FILL: begin
            heater = 1;
            washing_machine_load_size_detection(clk, reset, load_weight, water_level);
            if (water_level_sensor >= WATER_LEVEL) begin
                water_valve = 0;
                heater = 0;
                next_state = ADD_DETERGENT;
            end else begin
                next_state = HEAT_FILL;
            end
        end

        ADD_DETERGENT: begin
            detergent_valve = 1;
            #20; // Add some delay for detergent to mix
            next_state = WASH;
        end

        WASH: begin
            drum_motor = target_SPIN_SPEED;
            next_state = DRAIN_AFTER_WASH;
        end

        DRAIN_AFTER_WASH: begin
            drain_pump = 1;
            if (water_level_sensor == 0) begin
                drain_pump = 0;
                next_state = FILL_SOFTENER;
            end else begin
                next_state = DRAIN_AFTER_WASH;
            end
        end

        FILL_SOFTENER: begin
            water_valve = 1;
            if (water_level_sensor >= MAX_WATER_LEVEL) begin
                water_valve = 0;
                fabric_softener_valve = 1;
                next_state = RINSE;
            end else begin
                next_state = FILL_SOFTENER;
            end
        end

        RINSE: begin
            drum_motor = SPIN_SPEED_LOW;
            // Timer or duration logic to handle drying can be added here
            next_state = DRAIN_AFTER_RINSE;
        end

        DRAIN_AFTER_RINSE: begin
            drain_pump = 1;
            if (water_level_sensor == 0) begin
                next_state = DRY_SPIN;
            end else begin
                next_state = DRAIN_AFTER_RINSE;
            end
        end

        DRY_SPIN: begin
            drum_motor = 10'd8;
            drain_pump = 1;
            // Timer or duration logic to handle drying can be added here
            next_state = COMPLETE;
        end

        COMPLETE: begin
            drain_pump = 0;
            cycle_complete_led = 1;
            door_lock = 0;
            next_state = IDLE;
        end

        default: next_state = IDLE;
    endcase
end

    // Logic to set the target temperature and spin speed based on user input
   always @(*) begin
    // Access the arrays using wash_mode as the index
    target_temperature = target_temperature_array[wash_mode];
    target_SPIN_SPEED = target_SPIN_SPEED_array[wash_mode];
    end

endmodule


module washing_machine_load_size_detection(
    input wire clk,        // Clock signal
    input wire reset,      // Reset signal
    input wire [7:0] load_weight, // Load sensor input representing the weight of clothes
    output reg [2:0] water_level  // 3-bit water level output: 0 for Low, 1 for Medium, 2 for High
);

// Thresholds for load weight to determine water level
parameter LOW_THRESHOLD = 8'd20;    // 20 units of weight for Low water level
parameter MEDIUM_THRESHOLD = 8'd50; // 50 units of weight for Medium water level
parameter HIGH_THRESHOLD = 8'd80;   // 80 units of weight for High water level

// State machine to control water level
always @(posedge clk or posedge reset) begin
    if (reset) begin
        water_level <= 3'd0; // Reset to Low water level
    end else begin
        if (load_weight <= LOW_THRESHOLD) begin
            water_level <= 3'd0; // Low water level
        end else if (load_weight > LOW_THRESHOLD && load_weight <= MEDIUM_THRESHOLD) begin
            water_level <= 3'd1; // Medium water level
        end else if (load_weight > MEDIUM_THRESHOLD && load_weight <= HIGH_THRESHOLD) begin
            water_level <= 3'd2; // High water level
        end else begin
            water_level <= 3'd3; // Extra High water 
        end
    end
end

endmodule