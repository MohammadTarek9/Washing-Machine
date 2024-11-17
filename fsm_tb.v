`timescale 100ms / 100ms
module fsm_tb();
    reg clk;
    reg reset;
    reg start;
    reg stop;
    reg pause;
    reg continue_signal;
    reg door_locked;
    reg clothes_loaded;
    reg vibration_sensor;
    reg [6:0] temperature_adc_sensor;
    reg [2:0] wash_mode;
    reg confirm_wash_mode;
    reg change_temperature;
    reg change_spin_speed;
    reg [9:0] water_level_sensor;
    reg timer_done;
    reg [5:0] selected_temperature;
    reg [10:0] selected_spin_speed;
    reg [9:0] water_level;
    reg water_flow_error;
    wire timer_enable;
    wire timer_reset;
    wire [15:0] timer_period;
    wire temp_reset;
    wire speed_reset;
    wire water_flow_mode;
    wire water_flow_reset;
    wire cycle_complete_led;
    wire door_lock;
    wire water_valve;
    wire heater;
    wire drain_pump;
    wire [10:0] drum_motor;
    wire water_flow_error_led;
    wire drainage_error_led;
    wire vibration_error_led;
    WashingMachineFSM dut(
        .clk(clk),
        .reset(reset),
        .start(start),
        .stop(stop),
        .pause(pause),
        .continue_signal(continue_signal),
        .door_locked(door_locked),
        .clothes_loaded(clothes_loaded),
        .vibration_sensor(vibration_sensor),
        .temperature_adc_sensor(temperature_adc_sensor),
        .wash_mode(wash_mode),
        .confirm_wash_mode(confirm_wash_mode),
        .change_temperature(change_temperature),
        .change_spin_speed(change_spin_speed),
        .water_level_sensor(water_level_sensor),
        .timer_done(timer_done),
        .selected_temperature(selected_temperature),
        .selected_spin_speed(selected_spin_speed),
        .water_level(water_level),
        .water_flow_error(water_flow_error),
        .timer_enable(timer_enable),
        .timer_reset(timer_reset),
        .timer_period(timer_period),
        .temp_reset(temp_reset),
        .speed_reset(speed_reset),
        .water_flow_mode(water_flow_mode),
        .water_flow_reset(water_flow_reset),
        .cycle_complete_led(cycle_complete_led),
        .door_lock(door_lock),
        .water_valve(water_valve),
        .heater(heater),
        .drain_pump(drain_pump),
        .drum_motor(drum_motor),
        .water_flow_error_led(water_flow_error_led),
        .drainage_error_led(drainage_error_led),
        .vibration_error_led(vibration_error_led)
    );
    initial begin
        clk = 0;
        forever
        #1 clk = ~clk;
    end
    
    initial begin
        //initializations
        reset = 1;
        start = 0;
        stop = 0;
        pause = 0;
        continue_signal = 0;
        door_locked = 0;
        clothes_loaded = 0;
        vibration_sensor = 0;
        temperature_adc_sensor = 7'd0;
        wash_mode = 3'b0;
        confirm_wash_mode = 0;
        change_temperature = 0;
        change_spin_speed = 0;
        water_level_sensor = 10'd0;
        timer_done=0;
        selected_temperature = 6'd0;
        selected_spin_speed = 11'd0;
        water_level = 10'd0;
        water_flow_error = 0;

        #8
        reset = 0;
        #8
        // Test FSM transitions
        // IDLE -> START
        $display("Testing IDLE -> START");
        reset=0;
        start=1;
        clothes_loaded=1;
        door_locked=1;
        #8;
        if (dut.current_state != dut.START) $display("Failed IDLE -> START!");
        else $display("Passed IDLE -> START!");
        #8
        // START -> FILL_INITIAL
        $display("Testing START -> FILL_INITIAL");
        wash_mode = 3'd0;
        confirm_wash_mode = 1;
        selected_temperature = 6'd40;
        selected_spin_speed = 11'd1400;
        #8
        if (dut.current_state != dut.FILL_INITIAL) $display("Failed START -> FILL_INITIAL!");
        else $display("Passed START -> FILL_INITIAL!");
        #8
        // FILL_INITIAL -> HEAT_FILL
        $display("Testing FILL_INITIAL -> HEAT_FILL");
        water_level_sensor = 10'd110;
        water_level=300;
        #8
        if (dut.current_state != dut.HEAT_FILL) $display("Failed FILL_INITIAL -> HEAT_FILL!");
        else $display("Passed FILL_INITIAL -> HEAT_FILL!");
        #8
        // HEAT_FILL -> WASH
        $display("Testing HEAT_FILL -> WASH");
        water_level_sensor=10'd180;
        temperature_adc_sensor=7'd10;
        #2
        water_level_sensor=10'd300;
        temperature_adc_sensor=7'd40;
        #8
        if (dut.current_state != dut.WASH) $display("Failed HEAT_FILL -> WASH!");
        else $display("Passed HEAT_FILL -> WASH!");
        #8
        // WASH -> DRAIN_AFTER_WASH
        $display("Testing WASH -> DRAIN_AFTER_WASH");
        timer_done=1;
        #8
        if (dut.current_state != dut.DRAIN_AFTER_WASH) $display("Failed WASH -> DRAIN_AFTER_WASH!");
        else $display("Passed WASH -> DRAIN_AFTER_WASH!");
        timer_done=0;
        #8
        // DRAIN_AFTER_WASH -> FILL_BEFORE_RINSE
        $display("Testing DRAIN_AFTER_WASH -> FILL_BEFORE_RINSE");
        water_level_sensor=10'd80;
        #2
        water_level_sensor=10'd0;
        #8
        if (dut.current_state != dut.FILL_BEFORE_RINSE) $display("Failed DRAIN_AFTER_WASH -> FILL_BEFORE_RINSE!");
        else $display("Passed DRAIN_AFTER_WASH -> FILL_BEFORE_RINSE!");
        #8
        // FILL_BEFORE_RINSE -> RINSE
        $display("Testing FILL_BEFORE_RINSE -> RINSE");
        water_level_sensor=10'd180;
        #2
        water_level_sensor=10'd300;
        #8
        if (dut.current_state != dut.RINSE) $display("Failed FILL_BEFORE_RINSE -> RINSE!");
        else $display("Passed FILL_BEFORE_RINSE -> RINSE!");
        #8
        // RINSE -> DRAIN_AFTER_RINSE
        $display("Testing RINSE -> DRAIN_AFTER_RINSE");
        timer_done=1;
        #8
        if (dut.current_state != dut.DRAIN_AFTER_RINSE) $display("Failed RINSE -> DRAIN_AFTER_RINSE!");
        else $display("Passed RINSE -> DRAIN_AFTER_RINSE!");
        timer_done=0;
        #8
        // DRAIN_AFTER_RINSE -> DRY_SPIN
        $display("Testing DRAIN_AFTER_RINSE -> DRY_SPIN");
        water_level_sensor=10'd50;
        #2
        water_level_sensor=10'd0;
        #8
        if (dut.current_state != dut.DRY_SPIN) $display("Failed DRAIN_AFTER_RINSE -> DRY_SPIN!");
        else $display("Passed DRAIN_AFTER_RINSE -> DRY_SPIN!");
        #8
        // DRY_SPIN -> COMPLETE
        $display("Testing DRY_SPIN -> COMPLETE");
        timer_done=1;
        #2
        if (dut.current_state != dut.COMPLETE) $display("Failed DRY_SPIN -> COMPLETE!");
        else $display("Passed DRY_SPIN -> COMPLETE!");
        timer_done=0;
        #2
        // COMPLETE -> IDLE
        $display("Testing COMPLETE -> IDLE");
        if (dut.current_state != dut.IDLE) $display("Failed COMPLETE -> IDLE!");
        else $display("Passed COMPLETE -> IDLE!");
        #6
        /////////////////////////////////////////////////////////////////////////////

        reset = 1;
        start = 0;
        stop = 0;
        pause = 0;
        continue_signal = 0;
        door_locked = 0;
        clothes_loaded = 0;
        vibration_sensor = 0;
        temperature_adc_sensor = 7'd0;
        wash_mode = 3'b0;
        confirm_wash_mode = 0;
        change_temperature = 0;
        change_spin_speed = 0;
        water_level_sensor = 10'd0;
        timer_done=0;
        selected_temperature = 6'd0;
        selected_spin_speed = 11'd0;
        water_level = 10'd0;
        water_flow_error = 0;

        #8
        reset = 0;
        #8
        // Test FSM transitions
        // IDLE -> START
        reset=0;
        start=1;
        clothes_loaded=1;
        door_locked=1;
        #16
        // START -> FILL_INITIAL
        wash_mode = 3'd0;
        confirm_wash_mode = 1;
        selected_temperature = 6'd40;
        selected_spin_speed = 11'd1400;
        #16
        // FILL_INITIAL -> HEAT_FILL
        $display("Enabling error at Current State: ", dut.current_state);
        vibration_sensor = 1;
        #4
        $display("Current State: ", dut.current_state); 
        $display("Turning off error");
        vibration_sensor = 0;
        continue_signal = 1;
        #4
        continue_signal = 0;
        $display("Current State: ", dut.current_state);
        #4
        water_level_sensor = 10'd110;
        water_level=300;
        #16
        // HEAT_FILL -> WASH
        $display("Enabling error at Current State: ", dut.current_state);
        water_flow_error = 1;
        #4
        $display("Current State: ", dut.current_state); 
        $display("Turning off error");
        water_flow_error = 0;
        continue_signal = 1;
        #4
        continue_signal = 0;
        $display("Current State: ", dut.current_state);
        #4
        water_level_sensor=10'd180;
        temperature_adc_sensor=7'd10;
        #2
        water_level_sensor=10'd300;
        temperature_adc_sensor=7'd40;
        #16
        // // WASH -> DRAIN_AFTER_WASH
        $display("Enabling error at Current State: ", dut.current_state);
        vibration_sensor = 1;
        #4
        $display("Current State: ", dut.current_state);
        $display("Turning off error");
        vibration_sensor = 0;
        continue_signal = 1;
        #4
        continue_signal = 0;
        $display("Current State: ", dut.current_state);
        #2
        timer_done=1;
        #16
        
        // DRAIN_AFTER_WASH -> FILL_BEFORE_RINSE
        $display("Enabling error at Current State: ", dut.current_state);
        timer_done=0;
        water_flow_error = 1;
        #4
        $display("Current State: ", dut.current_state);
        $display("Turning off error");
        water_flow_error = 0;
        continue_signal = 1;
        #4
        continue_signal = 0;
        $display("Current State: ", dut.current_state);
        #2
        water_level_sensor=10'd80;
        #2
        water_level_sensor=10'd0;
        #8

        // FILL_BEFORE_RINSE -> RINSE        
        $display("Enabling error at Current State: ", dut.current_state);
        water_flow_error = 1;
        #4
        $display("Current State: ", dut.current_state); 
        $display("Turning off error");
        water_flow_error = 0;
        continue_signal = 1;
        #4
        continue_signal = 0;
        $display("Current State: ", dut.current_state);
        #4
        water_level_sensor=10'd180;
        #2
        water_level_sensor=10'd300;
        #8
        
        // RINSE -> DRAIN_AFTER_RINSE
        $display("Enabling error at Current State: ", dut.current_state);
        water_flow_error = 1;
        #4
        $display("Current State: ", dut.current_state); 
        $display("Turning off error");
        water_flow_error = 0;
        continue_signal = 1;
        #4
        continue_signal = 0;
        $display("Current State: ", dut.current_state);
        #4
        ////////////////////////////////////////////////////////
        $display("Stopping!!!");
        stop = 1;
        #4 $display("Current State: ", dut.current_state);
        water_level_sensor = 0;
        stop = 0;
        #8 $display("Current State: ", dut.current_state);
        ///////////////////////////////////////////////////////////
        timer_done=1;
        #8
        timer_done=0;
        #8
        // DRAIN_AFTER_RINSE -> DRY_SPIN
        $display("Enabling error at Current State: ", dut.current_state);
        water_flow_error = 1;
        #4
        $display("Current State: ", dut.current_state); 
        $display("Turning off error");
        water_flow_error = 0;
        continue_signal = 1;
        #4
        continue_signal = 0;
        $display("Current State: ", dut.current_state);
        #4
        water_level_sensor=10'd50;
        #2
        water_level_sensor=10'd0;
        #8
        
        // DRY_SPIN -> COMPLETE
        $display("Enabling error at Current State: ", dut.current_state);
        vibration_sensor = 1;
        #4
        $display("Current State: ", dut.current_state); 
        $display("Turning off error");
        vibration_sensor = 0;
        continue_signal = 1;
        #4
        continue_signal = 0;
        $display("Current State: ", dut.current_state);
        #4
        timer_done=1;
        #2
        $display("Current State: ", dut.current_state);
        timer_done=0;
        // // COMPLETE -> IDLE
        // $display("Testing COMPLETE -> IDLE");
        // if (dut.current_state != dut.IDLE) $display("Failed COMPLETE -> IDLE!");
        // else $display("Passed COMPLETE -> IDLE!");
        #6 $stop;
        

    end

endmodule