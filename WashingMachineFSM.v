module WashingMachineFSM(
    input clk,
    input reset,
    input start,
    input stop,
    input pause,
    input continue_signal,
    input door_locked,
    input clothes_loaded,
    input vibration_sensor,
    input [6:0] temperature_adc_sensor,
    input [2:0] wash_mode,
    input confirm_wash_mode,
    input [9:0] water_level_sensor,
    input timer_done,
    input [5:0] selected_temperature,
    input [10:0] selected_spin_speed,
    input [9:0] water_level,
    input water_flow_error,
    output reg timer_enable,
    output reg timer_reset,
    output reg [3:0] timer_period,
    output reg temp_reset,
    output reg speed_reset,
    output reg water_flow_mode,
    output reg water_flow_reset,
    output reg cycle_complete_led,
    output reg door_lock,
    output reg water_valve,
    output reg detergent_valve,
    output reg heater,
    output reg drain_pump,
    output reg [10:0] drum_motor, //changed
    output reg water_flow_error_led,
    output reg drainage_error_led,
    output reg vibration_error_led
);
//all states of the washing machine
parameter [3:0] IDLE = 4'b0000;
parameter [3:0] START = 4'b0001;
parameter [3:0] FILL_INITIAL = 4'b0010;
parameter [3:0] HEAT_FILL = 4'b0011;
parameter [3:0] WASH = 4'b0100;
parameter [3:0] DRAIN_AFTER_WASH = 4'b0101;
parameter [3:0] FILL_BEFORE_RINSE = 4'b0110;
parameter [3:0] RINSE = 4'b0111;
parameter [3:0] DRAIN_AFTER_RINSE = 4'b1000;
parameter [3:0] DRY_SPIN = 4'b1001;
parameter [3:0] COMPLETE = 4'b1010;
parameter [3:0] PAUSE = 4'b1011;
parameter [3:0] CANCEL_DRAIN = 4'b1100;  // New state for handling cancel drain

//all possible wash modes
parameter [2:0] COTTON = 3'b000;
parameter [2:0] SYNTHETICS = 3'b001;
parameter [2:0] DRUM_CLEAN = 3'b010; //no clothes in drum
parameter [2:0] QUICK_WASH = 3'b011; 
parameter [2:0] DAILY_WASH = 3'b100;
parameter [2:0] DELICATES = 3'b101;
parameter [2:0] WOOL = 3'b110;
parameter [2:0] COLOURS = 3'b111;

//times for each mode
parameter [3:0] time_COTTON = 4'd10;  
parameter [3:0] time_SYNTHETICS = 4'd15;  
parameter [3:0] time_DRUM_CLEAN = 4'd12;  
parameter [3:0] time_QUICK_WASH = 4'd5;  
parameter [3:0] time_DAILY_WASH = 4'd8;  
parameter [3:0] time_DELICATES = 4'd6;  
parameter [3:0] time_WOOL = 4'd7;  
parameter [3:0] time_COLOURS = 4'd9;  

parameter [6:0] GENERAL_WATER_LEVEL=7'd100;
//missing signals
reg [3:0] current_state, next_state, prev_state;
reg [14:0] selected_time;
reg water_flow_error_flag, water_drainage_error_flag, vibration_error_flag;


always @(posedge clk or posedge reset) begin
    if (reset) begin
        current_state <= IDLE;
        prev_state <= IDLE;
        selected_time <= 14'd0;
        timer_enable <= 0;
        water_flow_error_flag <= 0;
        water_drainage_error_flag <= 0;
        vibration_error_flag <= 0;
    end else begin
        current_state <= next_state;
        // Sequential logic for state-dependent variables
        if (vibration_sensor) begin
            vibration_error_flag <= 1;
            if (current_state != PAUSE) begin
                prev_state <= current_state;
            end
        end
        else if (water_flow_error) begin
            if (current_state == PAUSE) begin
                if (prev_state == FILL_BEFORE_RINSE || prev_state == HEAT_FILL || prev_state == FILL_INITIAL) begin
                    water_flow_error_flag <= 1;
                end 
                else begin
                    water_drainage_error_flag <= 1;
                end
            end
            else prev_state <= current_state;
        end 
        else if (pause && current_state != PAUSE) begin
            prev_state <= current_state;
        end
        else if (continue_signal) begin //////////////////////////
            water_flow_error_flag <= 0;
            water_drainage_error_flag <= 0;
            vibration_error_flag <= 0;
            next_state <= prev_state;
        end
    end
end

always @(*) begin
    // Default assignments
    water_valve = 0;
    detergent_valve = 0;
    heater = 0;
    drum_motor = 0;
    drain_pump = 0;
    cycle_complete_led = 0;
    timer_reset = 1;
    temp_reset = 0;
    speed_reset = 0;
    // water_flow_reset = 1;
    water_flow_mode = 1'bx;
    door_lock = 1;
    water_flow_error_led = water_flow_error_flag;
    drainage_error_led = water_drainage_error_flag;
    vibration_error_led = vibration_error_flag;
    next_state = current_state; // Default to hold state

    if (stop) begin
        next_state = CANCEL_DRAIN;
    end else if (vibration_error_flag || water_flow_error) begin
        next_state = PAUSE;
        timer_enable = 0;  // Disable the timer without resetting it
    end else if (pause && current_state != PAUSE) begin
        next_state = PAUSE;
        timer_enable = 0;  // Disable the timer without resetting it
    end else if (current_state == PAUSE && continue_signal) begin
        next_state = prev_state;
        timer_enable = 1;  // Enable the timer to continue from where it was paused
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
                water_flow_reset = 1;
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
                heater=1;
                water_valve=1;
                detergent_valve=1;
                water_flow_mode = 1;   // Filling mode
                water_flow_reset = 0;
                if(water_level_sensor>=water_level) begin
                    water_valve=0;
                    detergent_valve=0;
                    water_flow_reset = 1;
                end
                else begin
                    water_valve=1;
                    detergent_valve=1;
                end
                if(temperature_adc_sensor>=selected_temperature) begin
                    heater=0;
                end
                else begin 
                    heater=1;
                end
                if(heater==0 && water_valve==0 && detergent_valve==0) begin
                    next_state=WASH;
                end
                else next_state=HEAT_FILL;
            end

            WASH: begin
                water_flow_reset=1;
                timer_period=selected_time/2;
                timer_enable=1;
                timer_reset=0;
                drum_motor = selected_spin_speed;
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
                    next_state = FILL_BEFORE_RINSE;
                end else begin
                    next_state = DRAIN_AFTER_WASH;
                end
            end
            FILL_BEFORE_RINSE: begin
                water_valve=1;
                water_flow_mode = 1;   // Filling mode
                water_flow_reset = 0;
                if (water_level_sensor >= water_level) begin
                    next_state = RINSE;
                end else begin
                    next_state = FILL_BEFORE_RINSE;
                end
            end

            RINSE: begin
                water_flow_reset = 1;
                timer_period=selected_time/5;
                timer_enable=1;
                timer_reset=0;
                drum_motor = selected_spin_speed;
                if(timer_done==1) begin
                    next_state=DRAIN_AFTER_RINSE;
                end
                else begin
                    next_state=RINSE;
                end
            end

            DRAIN_AFTER_RINSE: begin
                drum_motor = 0;
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
                drum_motor = selected_spin_speed;
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