module washing_machine_controller (
    input clk,                   // Clock signal
    input reset,                 // Reset signal
    input start,                 // Start button
    input stop,                  // Stop button
    input [1:0] wash_cycle,      // Wash cycle selector (00 = Normal, 01 = Delicate, 10 = Heavy Duty, 11 = Quick Wash)
    input [1:0] temperature,     // Temperature selector (00 = Cold, 01 = Warm, 10 = Hot)
    input [1:0] spin_speed,      // Spin speed selector (00 = Low, 01 = Medium, 10 = High)
    input door_locked,           // Door lock sensor (1 = Locked, 0 = Unlocked)
    input [9:0] water_level,     // Water level sensor (10-bit ADC output)
    input [9:0] temperature_adc, // Temperature sensor ADC output
    input [9:0] motor_speed_sensor, // Motor speed sensor (Tachometer)
    input vibration_sensor,      // Vibration sensor (1 = Excessive vibration)

    output reg water_valve,           // Control for water valve (1 = Open, 0 = Close)
    output reg heater,                // Control for heater (1 = On, 0 = Off)
    output reg drum_motor,            // Control for drum motor (1 = On, 0 = Off)
    output reg drain_pump,            // Control for drain pump (1 = On, 0 = Off)
    output reg door_lock,             // Control for door lock (1 = Locked, 0 = Unlocked)
    output reg cycle_complete_led,    // LED indicator for cycle complete
    output reg error_led              // LED indicator for errors
);

// State encoding for the FSM
localparam [3:0] IDLE        = 4'b0000;
localparam [3:0] FILL        = 4'b0001;
localparam [3:0] WASH        = 4'b0010;
localparam [3:0] HEAT        = 4'b0011;
localparam [3:0] SPIN        = 4'b0100;
localparam [3:0] DRAIN       = 4'b0101;
localparam [3:0] COMPLETE    = 4'b0110;
localparam [3:0] ERROR_STATE = 4'b0111;

reg [3:0] current_state, next_state;

// Parameters for cycle durations, water level thresholds, and temperatures
parameter MAX_WATER_LEVEL = 10'd512;
parameter WASH_TEMP_WARM = 10'd300;
parameter WASH_TEMP_HOT  = 10'd600;
parameter MAX_SPIN_SPEED = 10'd1200;

// Registers to store the selected cycle parameters
reg [9:0] target_temperature;
reg [9:0] target_spin_speed;
reg [9:0] target_wash_speed;

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
            if (start && door_locked) begin
                door_lock = 1;
                next_state = FILL;
            end else begin
                next_state = IDLE;
            end
        end
        
        FILL: begin
            water_valve = 1;
            if (water_level >= MAX_WATER_LEVEL) begin
                water_valve = 0;
                next_state = WASH;
            end else begin
                next_state = FILL;
            end
        end
        
        WASH: begin
            drum_motor = 1;

            // Set the washing speed based on the wash cycle
            case (wash_cycle)
                2'b00: target_wash_speed = 10'd60;   // Normal Mode (60 RPM)
                2'b01: target_wash_speed = 10'd30;   // Delicate Mode (30 RPM)
                2'b10: target_wash_speed = 10'd90;   // Heavy Duty Mode (90 RPM)
                2'b11: target_wash_speed = 10'd60;   // Quick Wash Mode (60 RPM)
                default: target_wash_speed = 10'd60;
            endcase
            
            
            // Transition to HEAT or SPIN depending on temperature
            next_state = (temperature_adc < target_temperature) ? HEAT : SPIN;
        end
        
        HEAT: begin
            heater = 1;

            // Maintain the drum motor at the targeted wash speed during heating
            drum_motor = 1;

            // Ensure drum speed is maintained during heating
            if (motor_speed_sensor >= target_wash_speed) begin
                drum_motor = 0;
            end

            // Continue heating until the temperature reaches the target
            if (temperature_adc >= target_temperature) begin
                heater = 0;
                next_state = SPIN;
            end else begin
                next_state = HEAT;
            end
        end
        
         SPIN: begin
            drum_motor = 1;

            // Set spin duration based on selected mode
            case (wash_cycle)
                2'b00: spin_duration = NORMAL_SPIN_DURATION;        // Normal Mode
                2'b01: spin_duration = DELICATE_SPIN_DURATION;      // Delicate Mode
                2'b10: spin_duration = HEAVY_DUTY_SPIN_DURATION;    // Heavy Duty Mode
                2'b11: spin_duration = QUICK_WASH_SPIN_DURATION;    // Quick Wash Mode
                default: spin_duration = ECO_SPIN_DURATION;         // Default: Eco Mode or others
            endcase
            
            // Handle custom spin duration
            if (wash_cycle == 2'b11 && custom_spin_duration != 0) begin
                spin_duration = custom_spin_duration;
            end
            
            // Stop the spin after the duration is reached
            if (spin_timer >= spin_duration) begin
                drum_motor = 0;
                next_state = DRAIN;
            end

            // Handle excessive vibration during spin cycle
            if (vibration_sensor) begin
                drum_motor = 0;  // Stop the motor
                next_state = ERROR_STATE;  // Transition to error state
            end
        end
        
        DRAIN: begin
            drain_pump = 1;
            if (water_level == 0) begin
                drain_pump = 0;
                next_state = COMPLETE;
            end else begin
                next_state = DRAIN;
            end
        end
        
        COMPLETE: begin
            cycle_complete_led = 1;
            door_lock = 0;
            next_state = IDLE;
        end
        
        ERROR_STATE: begin
            error_led = 1;
            // Reset system after an error and unlock the door
            if (reset) begin
                door_lock = 0;
                next_state = IDLE;
            end
        end
        
        default: next_state = IDLE;
    endcase
end

// Logic to set the target temperature and spin speed based on user input
always @(*) begin
    case (temperature)
        2'b00: target_temperature = 10'd100;  // Cold
        2'b01: target_temperature = WASH_TEMP_WARM;  // Warm
        2'b10: target_temperature = WASH_TEMP_HOT;   // Hot
        default: target_temperature = 10'd100;
    endcase
    
    case (spin_speed)
        2'b00: target_spin_speed = 10'd400;  // Low
        2'b01: target_spin_speed = 10'd800;  // Medium
        2'b10: target_spin_speed = MAX_SPIN_SPEED;  // High
        default: target_spin_speed = 10'd400;
    endcase
end

endmodule
