module Washing_Machine(
    input clk,
    input reset,
    input start,
    input stop,
    input pause,
    input continue_signal,
    input door_locked,  //(1=locked, 0=unlocked)
    input clothes_loaded,
    input [7:0] load_weight,
    input vibration_sensor, //1 for excessive vibration
    input [6:0] temperature_adc_sensor, //temperature sensor ADC output
    input [2:0] wash_mode,  //wash mode for the wm
    input confirm_wash_mode,
    input change_temperature,
    input change_spin_speed,
    input [9:0] water_level_sensor, //sensor for water level
    input [9:0] motor_speed_sensor, //NOT HANDLED IN CODE
    output reg cycle_complete_led,    // LED indicator for cycle complete
    output reg door_lock,
    output reg water_valve,
    output reg heater,
    output reg drain_pump,
    output reg [3:0]drum_motor,  
    output reg water_flow_error_led,   // LED indicator for water flow error
    output reg drainage_error_led,     // LED indicator for drainage error
    output reg vibration_error_led   // LED indicator for vibration error
);

//wash time, changing between discrete values
//all possible temperature values
parameter [5:0] temperature_10=6'd10;
parameter [5:0] temperature_20=6'd20;
parameter [5:0] temperature_30=6'd30;
parameter [5:0] temperature_40=6'd40;
parameter [5:0] temperature_60=6'd60;
//parameter [5:0] temperature_90=7'd90;

//all possible spin speeds
parameter [10:0] no_spin_speed = 11'd0;
parameter [10:0] spin_speed_400 = 11'd400;
parameter [10:0] spin_speed_800 = 11'd800;
parameter [10:0] spin_speed_1200 = 11'd1200;
parameter [10:0] spin_speed_1400 = 11'd1400;

//thresholds
parameter [6:0] GENERAL_WATER_LEVEL=7'd100;

//all states of the washing machine
parameter [3:0] IDLE = 4'b0000;
parameter [3:0] START = 4'b0001;
parameter [3:0] FILL_INITIAL = 4'b0010;
parameter [3:0] HEAT_FILL = 4'b0011;
parameter [3:0] WASH = 4'b0100;
parameter [3:0] DRAIN_AFTER_WASH = 4'b0101;
parameter [3:0] RINSE = 4'b0111;
parameter [3:0] DRAIN_AFTER_RINSE = 4'b1000;
parameter [3:0] DRY_SPIN = 4'b1001;
parameter [3:0] COMPLETE = 4'b1010;
parameter [3:0] PAUSE = 4'b1011;
parameter [3:0] CANCEL_DRAIN = 4'b1101;  // New state for handling cancel drain

reg [3:0] current_state, next_state;
wire [10:0] selected_spin_speed; //changed from reg
reg [13:0] selected_time;
reg [2:0] program;

//all possible wash modes
parameter [2:0] COTTON = 3'b000;
parameter [2:0] SYNTHETICS = 3'b001;
parameter [2:0] DRUM_CLEAN = 3'b010; //no clothes in drum
parameter [2:0] QUICK_WASH = 3'b011; 
parameter [2:0] DAILY_WASH = 3'b100;
parameter [2:0] DELICATES = 3'b101;
parameter [2:0] WOOL = 3'b110;
parameter [2:0] COLOURS = 3'b111;



// temperatures for each mode
parameter [5:0] temp_COTTON = temperature_40;
parameter [5:0] temp_SYNTHETICS = temperature_40;
parameter [5:0] temp_DRUM_CLEAN = temperature_60;
parameter [5:0] temp_QUICK_WASH = temperature_10;
parameter [5:0] temp_DAILY_WASH = temperature_40;
parameter [5:0] temp_DELICATES = temperature_30;
parameter [5:0] temp_WOOL = temperature_40;
parameter [5:0] temp_COLOURS = temperature_40;

// spin speeds for each mode
parameter [10:0] spin_COTTON = spin_speed_1400;
parameter [10:0] spin_SYNTHETICS = spin_speed_1400;
parameter [10:0] spin_DRUM_CLEAN = spin_speed_1200;  
parameter [10:0] spin_QUICK_WASH = spin_speed_800;
parameter [10:0] spin_DAILY_WASH = spin_speed_1400;
parameter [10:0] spin_DELICATES = spin_speed_400;
parameter [10:0] spin_WOOL = spin_speed_800;
parameter [10:0] spin_COLOURS = spin_speed_1400;

//times for each mode
parameter [3:0] time_COTTON = 4'd10;  
parameter [3:0] time_SYNTHETICS = 4'd15;  
parameter [3:0] time_DRUM_CLEAN = 4'd12;  
parameter [3:0] time_QUICK_WASH = 4'd5;  
parameter [3:0] time_DAILY_WASH = 4'd8;  
parameter [3:0] time_DELICATES = 4'd6;  
parameter [3:0] time_WOOL = 4'd7;  
parameter [3:0] time_COLOURS = 4'd9;  

reg timer_enable=0; //it is wire in the timer
reg timer_reset;
wire timer_done;
reg [15:0] clk_freq = 16'd5;  //1Hz
reg [15:0] timer_period; //changes with every state

reg temp_reset;
reg speed_reset;

reg pause_prev, continue_prev; 
reg pause_pulse;          // Register to detect pause pulse
reg continue_pulse;       // Register to detect continue pulse
reg [3:0] prev_state;     // Store previous state when paused

// Declare signals for WaterFlowMonitor integration
reg water_flow_mode;
reg water_flow_reset;
wire water_flow_error;

wire [9:0] water_level; 
wire [5:0] selected_temperature;

reg water_flow_error_flag;
reg water_drainage_error_flag;
reg vibration_error_flag;

// Instantiate WaterFlowMonitor
WaterFlowMonitor water_flow_monitor_inst (
    .clk(clk),
    .reset(water_flow_reset),
    .water_level_sensor(water_level_sensor),
    .mode(water_flow_mode),
    .error_flag(water_flow_error)
);


timer timermod (
    .clk(clk),
    .reset(timer_reset),
    .enable(timer_enable),
    .clk_freq(clk_freq),
    .timer_period(timer_period),
    .done(timer_done)
);

temperature_incrementor_lut temp_selector (
    .clk(clk),
    .reset(temp_reset),
    .wash_mode(wash_mode),
    .increment(change_temperature),  // Use change_temperature signal as increment
    .selected_temperature(selected_temperature)
);

spin_speed_incrementor_lut speed_selector (
    .clk(clk),
    .reset(speed_reset),
    .wash_mode(wash_mode),
    .increment(change_spin_speed),   // Use change_spin_speed signal as increment
    .selected_spin_speed(selected_spin_speed)
);

washing_machine_load_size_detection load_detector (
    .clk(clk),
    .reset(reset),
    .load_weight(load_weight),
    .water_level(water_level)
);


always @(posedge clk or posedge reset) begin
    if (reset) begin
        current_state <= IDLE;
        prev_state <= IDLE;
        pause_pulse <= 0;
        continue_pulse <= 0;
        pause_prev <= 0;
        continue_prev <= 0;
        //selected_spin_speed <= 11'd0;
        selected_time <= 14'd0;
        timer_enable <= 0;
        water_flow_error_flag <= 0;
        water_drainage_error_flag <= 0;
        vibration_error_flag <= 0;
        // Initialize other sequential variables here
    end else begin
        current_state <= next_state;

        // Edge detection for pause and continue signals
        pause_pulse <= (pause && !pause_prev);           
        continue_pulse <= (continue_signal && !continue_prev);

        // Update previous values
        pause_prev <= pause;
        continue_prev <= continue_signal;

        // Sequential logic for state-dependent variables
        if (vibration_sensor) begin
            vibration_error_flag <= 1;
            if (current_state != PAUSE) begin
                prev_state <= current_state;
            end
        end else if (water_flow_error) begin
            if (water_flow_mode) begin
                water_flow_error_flag <= 1;
            end else begin
                water_drainage_error_flag <= 1;
            end
            if (current_state != PAUSE) begin
                prev_state <= current_state;
            end
        end else if (pause_pulse && current_state != PAUSE) begin
            prev_state <= current_state;
        end else if (continue_pulse) begin
            water_flow_error_flag <= 0;
            water_drainage_error_flag <= 0;
            vibration_error_flag <= 0;
        end

        // Update program and selected_time if transitioning to START state
        // if (current_state == IDLE && next_state == START) begin
        //     program <= wash_mode;
        //     case (wash_mode)
        //         COTTON: selected_time <= time_COTTON;
        //         SYNTHETICS: selected_time <= time_SYNTHETICS;
        //         // Add other cases here
        //         default: selected_time <= 0;
        //     endcase
        // end

        // Update other sequential variables as needed
    end
end

always @(*) begin
    // Default assignments
    water_valve = 0;
    heater = 0;
    drum_motor = 0;
    drain_pump = 0;
    cycle_complete_led = 0;
    timer_reset = 1;
    temp_reset = 0;
    speed_reset = 0;
    water_flow_reset = 1;
    water_flow_mode = 1'bx;
    door_lock = 1;
    water_flow_error_led = 0;
    drainage_error_led = 0;
    vibration_error_led = 0;
    next_state = current_state; // Default to hold state

    water_flow_error_flag = 0; //first edit
    water_drainage_error_flag = 0; //first edit
    vibration_error_flag = 0; //first edit

    if (stop) begin
        next_state = CANCEL_DRAIN;
    end else if (vibration_error_flag) begin
        vibration_error_led = 1;
        next_state = PAUSE;
    end else if (water_flow_error_flag || water_drainage_error_flag) begin
        water_flow_error_led = water_flow_error_flag;
        drainage_error_led = water_drainage_error_flag;
        next_state = PAUSE;
    end else if (pause_pulse && current_state != PAUSE) begin
        next_state = PAUSE;
    end else if (current_state == PAUSE && continue_pulse) begin
        next_state = prev_state;
    end else begin
        case (current_state)
            IDLE: begin
                //program = wash_mode;
                door_lock = 0;
                if (start && door_locked && clothes_loaded) begin
                    door_lock = 1;
                    next_state = START;
                end else begin
                    next_state = IDLE;
                end
            end
            
            START: begin
                if(confirm_wash_mode) begin
                temp_reset = 1;
                speed_reset = 1;
                case (wash_mode)
                    COTTON: begin
                        selected_time = time_COTTON;
                        next_state = FILL_INITIAL;
                    end
                    SYNTHETICS: begin
                        selected_time = time_SYNTHETICS;
                        next_state = FILL_INITIAL;
                    end
                    DRUM_CLEAN: begin
                        selected_time = time_DRUM_CLEAN;
                        next_state = FILL_INITIAL;
                    end
                    QUICK_WASH: begin
                        selected_time = time_QUICK_WASH;
                        next_state = FILL_INITIAL;
                    end
                    DAILY_WASH: begin
                        selected_time = time_DAILY_WASH;
                        next_state = FILL_INITIAL;
                    end
                    DELICATES: begin
                        selected_time = time_DELICATES;
                        next_state = FILL_INITIAL;
                    end
                    WOOL: begin
                        selected_time = time_WOOL;
                        next_state = FILL_INITIAL;
                    end
                    COLOURS: begin
                        selected_time = time_COLOURS;
                        next_state = FILL_INITIAL;
                    end
                    default: next_state = START;
                endcase
                //next_state = FILL_INITIAL;
            end
            else next_state = START;
            end
            
            FILL_INITIAL: begin
                water_valve=1;
                water_flow_mode = 1;   // Filling mode
                water_flow_reset = 0;
                if (water_level_sensor >= GENERAL_WATER_LEVEL) begin
                    next_state = HEAT_FILL;
                end else begin
                    next_state = FILL_INITIAL;
                end
            end

            HEAT_FILL: begin
                water_flow_mode = 1;   // Filling mode
                water_flow_reset = 0;
                if(water_level_sensor>=water_level) begin
                    water_valve=0;
                end
                else begin
                    water_valve=1;
                end
                if(temperature_adc_sensor>=selected_temperature) begin
                    heater=0;
                end
                else begin 
                    heater=1;
                end
                if(heater==0 && water_valve==0) begin
                    next_state=WASH;
                end
                else next_state=HEAT_FILL;
            end

            WASH: begin
                timer_period=selected_time/2;
                timer_enable=1;
                timer_reset=0;
                drum_motor = selected_spin_speed;
                if(temperature_adc_sensor>=selected_temperature) begin
                    heater=0;
                end
                else begin 
                    heater=1;
                end
                if(timer_done==1) begin
                    next_state=DRAIN_AFTER_WASH;
                end
                else begin
                    next_state=WASH;
                end
            end

            DRAIN_AFTER_WASH: begin
                heater=0;
                drain_pump=1;
                drum_motor = 0;
                water_flow_mode = 0;   // Draining mode
                water_flow_reset = 0;
                if (water_level_sensor == 0) begin
                    drain_pump = 0;
                    next_state = RINSE;
                end else begin
                    next_state = DRAIN_AFTER_WASH;
                end
            end

            RINSE: begin
                timer_period=selected_time/5;
                timer_enable=1;
                timer_reset=0;
                drum_motor = 1;
                if(timer_done==1) begin
                    next_state=DRAIN_AFTER_RINSE;
                end
                else begin
                    next_state=RINSE;
                end
            end

            DRAIN_AFTER_RINSE: begin
                drain_pump=1;
                timer_reset=1;
                water_flow_mode = 0;   // Draining mode
                water_flow_reset = 0;
                if (water_level_sensor == 0) begin
                    drain_pump = 0;
                    next_state = DRY_SPIN;
                end else begin
                    next_state = DRAIN_AFTER_RINSE;
                end
            end

            DRY_SPIN: begin
                timer_period=selected_time/5;
                timer_enable=1;
                timer_reset=0;
                drum_motor = 8;
                if(timer_done==1) begin
                    next_state=COMPLETE;
                end
                else begin
                    next_state=DRY_SPIN;
                end
            end

            COMPLETE: begin
                timer_enable=0;
                cycle_complete_led = 1;
                next_state = IDLE;
            end


            PAUSE: begin
                timer_enable = 0;  // Disable the timer without resetting it
                // Indicate errors via LEDs if error flags are set
                if (water_flow_error_flag) begin
                    water_flow_error_led = 1;
                end else begin
                    water_flow_error_led = 0;
                end
                if (water_drainage_error_flag) begin
                    drainage_error_led = 1;
                end else begin
                    drainage_error_led = 0;
                end
                if (vibration_error_flag) begin
                    vibration_error_led = 1;
                end else begin
                    vibration_error_led = 0;
                end
                if (continue_pulse) begin
                    water_flow_error_flag = 0;      // Reset error flags
                    water_drainage_error_flag = 0;
                    vibration_error_flag = 0;
                    next_state = prev_state;        // Resume from the previous state
                end else begin
                    next_state = PAUSE;             // Stay in PAUSE state
                end
            end

            CANCEL_DRAIN: begin
                // Ensure safety by turning off other actuators
                heater = 0;
                drum_motor = 0;
                water_valve = 0;  // Close water valve to prevent filling
                drain_pump = 1;   // Activate drain pump to drain water
                water_flow_mode = 0;   // Set mode to draining
                water_flow_reset = 0;  // Enable WaterFlowMonitor for draining
                timer_enable = 0;      // Disable timer
                door_lock = 1;         // Keep door locked during draining

                // Check if water has been drained
                if (water_level_sensor == 0) begin
                    drain_pump = 0;    // Stop drain pump when water is drained
                    // Reset error flags (optional)
                    water_flow_error_flag = 0;
                    water_drainage_error_flag = 0;
                    vibration_error_flag = 0;
                    next_state = IDLE; // Return to IDLE state 
                end else begin
                    next_state = CANCEL_DRAIN; // Stay in CANCEL_DRAIN state until drained
                end
            end

            default: next_state = CANCEL_DRAIN;
        endcase

    end
end
endmodule

