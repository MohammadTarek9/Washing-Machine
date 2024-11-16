`timescale 100ms / 100ms
module washing_machine_tb();
    //inputs
    reg clk;
    reg reset;
    reg start;
    reg stop;
    reg pause;
    reg continue_signal;
    reg door_locked;  //(1=locked, 0=unlocked)
    reg clothes_loaded; //1 for clothes loaded
    reg [7:0] load_weight;
    reg vibration_sensor; //1 for excessive vibration
    reg [6:0] temperature_adc_sensor; //temperature sensor ADC output
    reg [2:0] wash_mode;  //wash mode for the wm
    reg confirm_wash_mode;
    reg change_temperature;
    reg change_spin_speed;
    reg [9:0] water_level_sensor; //sensor for water level
    reg [9:0] motor_speed_sensor;
    //outputs
    wire cycle_complete_led;    // LED indicator for cycle complete
    wire door_lock;
    wire water_valve;
    wire heater;
    wire drain_pump;
    wire [3:0] drum_motor;  
    wire water_flow_error_led;   // LED indicator for water flow error
    wire drainage_error_led;     // LED indicator for drainage error
    wire vibration_error_led;
    Washing_Machine dut(
        .clk(clk),
        .reset(reset),
        .start(start),
        .stop(stop),
        .pause(pause),
        .continue_signal(continue_signal),
        .door_locked(door_locked),
        .clothes_loaded(clothes_loaded),
        .load_weight(load_weight),
        .vibration_sensor(vibration_sensor),
        .temperature_adc_sensor(temperature_adc_sensor),
        .wash_mode(wash_mode),
        .confirm_wash_mode(confirm_wash_mode),
        .change_temperature(change_temperature),
        .change_spin_speed(change_spin_speed),
        .water_level_sensor(water_level_sensor),
        .motor_speed_sensor(motor_speed_sensor),
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
        load_weight = 8'd0;
        vibration_sensor = 0;
        temperature_adc_sensor = 7'd0;
        wash_mode = 3'bx;
        confirm_wash_mode = 0;
        change_temperature = 0;
        change_spin_speed = 0;
        water_level_sensor = 10'd0;
        motor_speed_sensor = 10'd0;
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
        #8;
        if (dut.current_state != dut.FILL_INITIAL) $display("Failed START -> FILL_INITIAL!");
        else $display("Passed START -> FILL_INITIAL!");
        #8
        // FILL_INITIAL -> HEAT_FILL
        $display("Testing FILL_INITIAL -> HEAT_FILL");
        water_level_sensor = 10'd110;
        #8
        if (dut.current_state != dut.HEAT_FILL) $fatal("Failed FILL_INITIAL -> HEAT_FILL!");
        else $display("Passed FILL_INITIAL -> HEAT_FILL!");



    end

endmodule