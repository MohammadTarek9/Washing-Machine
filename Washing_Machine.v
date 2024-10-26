module Washing_Machine(
    input clk,
    input reset,
    input start,
    input stop,
    input pause,
    input clothes_loaded, //signal to indicate if user put the clothes in the drum or not (1 for yes and 0 for no)
    input door_locked,  //(1=locked, 0=unlocked)
    input [7:0] load_weight,
    input vibration_sensor, //1 for excessive vibration
    input [6:0] temperature_adc_sensor, //temperature sensor ADC output
    input [3:0] wash_mode,  //wash mode for the wm
    //input change_temperature,
    //input change_spin_speed,
    //input [6:0] user_selected_temperature, //temperature selected by the user (10,20,30,40,60,90)
    //input [10:0] user_selected_spin_speed, //spin speed selected by the user (0,400,800,1200,1400) in rpm
    //input [13:0] selected_time, //measured in seconds
    input [9:0] water_level_sensor, //sensor for water level
    input [9:0] motor_speed_sensor, //NOT HANDLED IN CODE
    output reg cycle_complete_led,    // LED indicator for cycle complete
    output reg error_led,              // LED indicator for errors
    output reg door_lock,
    output reg water_valve,
    output reg heater,
    output reg drain_pump,
    output reg drum_motor
);

//wash time, changing between discrete values
//all possible temperature values
parameter [6:0] temperature_10=7'd10;
parameter [6:0] temperature_20=7'd20;
parameter [6:0] temperature_30=7'd30;
parameter [6:0] temperature_40=7'd40;
parameter [6:0] temperature_60=7'd60;
parameter [6:0] temperature_90=7'd90;

//all possible spin speeds
parameter [10:0] no_spin_speed = 11'd0;
parameter [10:0] spin_speed_400 = 11'd400;
parameter [10:0] spin_speed_800 = 11'd800;
parameter [10:0] spin_speed_1200 = 11'd1200;
parameter [10:0] spin_speed_1400 = 11'd1400;

//thresholds
parameter [6:0] GENERAL_WATER_LEVEL=7'd100;
parameter [6:0] WATER_LEVEL=7'd120;

//all states of the washing machine
parameter [3:0] IDLE = 4'b0000;
parameter [3:0] START = 4'b0001;
parameter [3:0] FILL_INITIAL = 4'b0010;
parameter [3:0] HEAT_FILL = 4'b0011;
parameter [3:0] WASH = 4'b0100;
parameter [3:0] DRAIN_AFTER_WASH = 4'b0101;
parameter [3:0] SPIN = 4'b0110;
parameter [3:0] RINSE = 4'b0111;
parameter [3:0] DRAIN_AFTER_RINSE = 4'b1000;
parameter [3:0] DRY_SPIN = 4'b1001;
parameter [3:0] COMPLETE = 4'b1010;
parameter [3:0] ERROR = 4'b1011;

reg [3:0] current_state, next_state;
reg [6:0] selected_temperature;
reg [10:0] selected_spin_speed;
reg [13:0] selected_time;

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
parameter [6:0] temp_COTTON = temperature_40;
parameter [6:0] temp_SYNTHETICS = temperature_40;
parameter [6:0] temp_DRUM_CLEAN = temperature_60;
parameter [6:0] temp_QUICK_WASH = temperature_10;
parameter [6:0] temp_DAILY_WASH = temperature_40;
parameter [6:0] temp_DELICATES = temperature_30;
parameter [6:0] temp_WOOL = temperature_40;
parameter [6:0] temp_COLOURS = temperature_40;

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
reg [15:0] clk_freq = 16'd1;  //1Hz
reg [15:0] timer_period; //changes with every state

timer timermod (
    .clk(clk),
    .reset(timer_reset),
    .enable(timer_enable),
    .clk_freq(clk_freq),
    .timer_period(timer_period),
    .done(timer_done)
);

always @(posedge clk or posedge reset) begin
    if (reset) begin
        current_state <= IDLE;
        selected_temperature <= 7'd0;
        selected_spin_speed <= 11'd0;
        selected_time <= 14'd0;
        timer_enable <= 0;
    end else begin
        current_state <= next_state;
    end
end

always @(*) begin
    water_valve=0;
    heater=0;
    drum_motor=0;
    drain_pump=0;
    cycle_complete_led = 0;
    error_led = 0;
    timer_reset=1;
    case (current_state)
        IDLE: begin
            if (start && door_locked && (clothes_loaded || wash_mode == DRUM_CLEAN)) begin
                next_state = START;
            end else begin
                next_state = IDLE;
            end
        end
        
        START: begin
            case (wash_mode) 
                COTTON: begin
                    selected_temperature = temp_COTTON;
                    selected_spin_speed = spin_COTTON;
                    selected_time = time_COTTON;
                    next_state = FILL_INITIAL;
                end
                SYNTHETICS: begin
                    selected_temperature = temp_SYNTHETICS;
                    selected_spin_speed = spin_SYNTHETICS;
                    selected_time = time_SYNTHETICS;
                    next_state = FILL_INITIAL;
                end
                DRUM_CLEAN: begin
                    selected_temperature = temp_DRUM_CLEAN;
                    selected_spin_speed = spin_DRUM_CLEAN;
                    selected_time = time_DRUM_CLEAN;
                    next_state = FILL_INITIAL;
                end
                QUICK_WASH: begin
                    selected_temperature = temp_QUICK_WASH;
                    selected_spin_speed = spin_QUICK_WASH;
                    selected_time = time_QUICK_WASH;
                    next_state = FILL_INITIAL;
                end
                DAILY_WASH: begin
                    selected_temperature = temp_DAILY_WASH;
                    selected_spin_speed = spin_DAILY_WASH;
                    selected_time = time_DAILY_WASH;
                    next_state = FILL_INITIAL;
                end
                DELICATES: begin
                    selected_temperature = temp_DELICATES;
                    selected_spin_speed = spin_DELICATES;
                    selected_time = time_DELICATES;
                    next_state = FILL_INITIAL;
                end
                WOOL: begin
                    selected_temperature = temp_WOOL;
                    selected_spin_speed = spin_WOOL;
                    selected_time = time_WOOL;
                    next_state = FILL_INITIAL;
                end
                COLOURS: begin
                    selected_temperature = temp_COLOURS;
                    selected_spin_speed = spin_COLOURS;
                    selected_time = time_COLOURS;
                    next_state = FILL_INITIAL;
                end
                default: next_state = START; //need to check this
            endcase
            // if(change_temperature) begin
            //     case(user_selected_temperature)
            //         temperature_10, temperature_20, temperature_30, temperature_40, temperature_60, temperature_90: begin
            //             selected_temperature = user_selected_temperature;
            //         end
            //         default: selected_temperature = selected_temperature; //possible latch
            //     endcase
            // end
            // else selected_temperature = selected_temperature;
            // if(change_spin_speed) begin
            //     case(user_selected_spin_speed)
            //         no_spin_speed, spin_speed_400, spin_speed_800, spin_speed_1200, spin_speed_1400: begin
            //             selected_spin_speed = user_selected_spin_speed;
            //         end
            //         default: selected_spin_speed = selected_spin_speed;
            //     endcase
            // end
            // else selected_spin_speed = selected_spin_speed;
            
        end

        FILL_INITIAL: begin
            water_valve=1;
            if (water_level_sensor >= GENERAL_WATER_LEVEL) begin
                next_state = HEAT_FILL;
            end else begin
                next_state = FILL_INITIAL;
            end
        end

        HEAT_FILL: begin
            heater=1;
            if(water_level_sensor>=WATER_LEVEL) begin
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
            if(timer_done==1) begin
                next_state=DRAIN_AFTER_WASH;
            end
            else begin
                next_state=WASH;
            end
        end

        DRAIN_AFTER_WASH: begin
            drain_pump=1;
            timer_reset=1;
            if (water_level_sensor == 0) begin
                drain_pump = 0;
                next_state = RINSE;
            end else begin
                next_state = DRAIN_AFTER_WASH;
            end
        end
        SPIN: begin
            drum_motor=1;
            timer_period=selected_time/10;
            timer_enable=1;
            timer_reset=0;
            if(timer_done==1) begin
                timer_reset=1;
                next_state=RINSE;
            end
            else next_state=SPIN;
        end

        RINSE: begin
            timer_period=selected_time/5;
            timer_enable=1;
            timer_reset=0;
            if(timer_done==1) begin
                next_state=DRAIN_AFTER_WASH;
            end
            else begin
                next_state=WASH;
            end
        end

        DRAIN_AFTER_RINSE: begin
            drain_pump=1;
            timer_reset=1;
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

        ERROR: begin
            error_led = 1;
            next_state = IDLE;
        end

        default: next_state = ERROR;
    endcase
end


endmodule

//instantiate timer module
