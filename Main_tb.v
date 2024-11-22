`timescale 100ms / 100ms
module Main_tb();
    reg clk;
    reg reset;
    reg start;
    reg stop;
    reg pause;
    reg continue_signal;
    reg door_locked;  //(1=locked, 0=unlocked)
    reg clothes_loaded;
    reg [7:0] load_weight;
    reg vibration_sensor; //1 for excessive vibration
    reg [6:0] temperature_adc_sensor; //temperature sensor ADC output
    reg [2:0] wash_mode;  //wash mode for the wm
    reg confirm_wash_mode;
    reg change_temperature;
    reg change_spin_speed;
    reg [9:0] water_level_sensor; //sensor for water level
    wire cycle_complete_led;    // LED indicator for cycle complete
    wire door_lock;
    wire water_valve;
    wire heater;
    wire drain_pump;
    wire [10:0] drum_motor;  
    wire water_flow_error_led;   // LED indicator for water flow error
    wire drainage_error_led;     // LED indicator for drainage error
    wire vibration_error_led;   // LED indicator for vibration error
    MainController dut(
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
        .load_weight(load_weight),
        .wash_mode(wash_mode),
        .confirm_wash_mode(confirm_wash_mode),
        .change_temperature(change_temperature),
        .change_spin_speed(change_spin_speed),
        .water_level_sensor(water_level_sensor),
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

        #4
        reset = 0;
        #4
        start = 1;
        clothes_loaded=1;
        door_locked=1;
        load_weight = 8'd50;
        wash_mode = 3'd0;
        #4;
        start = 0;
        if (dut.fsm_inst.current_state != dut.fsm_inst.START) $display("Failed IDLE -> START!");
        else $display("Passed IDLE -> START!");
        confirm_wash_mode = 1;
        #4
        if (dut.fsm_inst.current_state != dut.fsm_inst.FILL_INITIAL) $display("Failed START -> FILL_INITIAL!");
        else $display("Passed START -> FILL_INITIAL!");
        #2 water_level_sensor = 10'd200;
        #6 water_level_sensor = 10'd300;
        #6 temperature_adc_sensor = 'd40;
        #60 water_level_sensor = 0;
        #6 water_level_sensor = 'd300;
        #20 water_level_sensor = 0;
        #36
        ////////////////////////////////////////////////////////////
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

        #4 reset = 0;
        #4 start = 1;
        wash_mode = 3'd3;
        clothes_loaded=1;
        door_locked=1;
        load_weight = 8'd100;
        #4;
        #2 start = 0;
        if (dut.fsm_inst.current_state != dut.fsm_inst.START) $display("Failed IDLE -> START!");
        else $display("Passed IDLE -> START!");
        $display("Speed= ", dut.speed_selector.selected_spin_speed);
        $display("Temp= ", dut.temp_selector.selected_temperature);
        #2 change_spin_speed = 1;
        #2 
        change_spin_speed = 0;
        change_temperature = 1;
        #2 
        change_temperature = 0;
        confirm_wash_mode = 1;
        #4
        if (dut.fsm_inst.current_state != dut.fsm_inst.FILL_INITIAL) $display("Failed START -> FILL_INITIAL!");
        else $display("Passed START -> FILL_INITIAL!");
        #2 water_level_sensor = 10'd200;
        $display("Speed After= ", dut.speed_selector.selected_spin_speed);
        $display("Temp After= ", dut.temp_selector.selected_temperature);
        #6 water_level_sensor = 10'd900;
        #6 temperature_adc_sensor = 'd30;
        #28 water_level_sensor = 0;
        #6 water_level_sensor = 'd900;
        #20 water_level_sensor = 0;
        #36
        
        ////////////////////////////////////////////////////////////////////
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

        #4
        reset = 0;
        #4
        start = 1;
        clothes_loaded=1;
        door_locked=1;
        load_weight = 8'd50;
        wash_mode = 3'd0;
        #4;
        start = 0;
        if (dut.fsm_inst.current_state != dut.fsm_inst.START) $display("Failed IDLE -> START!");
        else $display("Passed IDLE -> START!");
        confirm_wash_mode = 1;
        #4
        if (dut.fsm_inst.current_state != dut.fsm_inst.FILL_INITIAL) $display("Failed START -> FILL_INITIAL!");
        else $display("Passed START -> FILL_INITIAL!");
        #2 water_level_sensor = 10'd200;
        #6 water_level_sensor = 10'd300;
        #6 temperature_adc_sensor = 'd40;
        
        #16 pause = 1;
        #4 pause = 0;
        #20 continue_signal = 1;
        #4 continue_signal = 0;
        
        #40 water_level_sensor = 0;
        #6 water_level_sensor = 'd300;
        
        #8 vibration_sensor = 1;
        #8 vibration_sensor = 0;
        #10 continue_signal = 1;
        #4 continue_signal = 0;
        
        #20 water_level_sensor = 0;
        #36 $stop;
    end

    initial begin
        $monitor("Time=%d, Current=%d,  Counter=%d", $time, dut.fsm_inst.current_state,  dut.timermod.counter);
    end

endmodule
