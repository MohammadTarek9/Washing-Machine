`timescale 100ms / 100ms
module washing_machine_tb();
    reg clk;
    reg reset;
    reg start;
    reg stop;
    reg pause;
    reg continue_signal;
    reg door_locked;  //(1=locked, 0=unlocked)
    reg [7:0] load_weight;
    reg vibration_sensor; //1 for excessive vibration
    reg [6:0] temperature_adc_sensor; //temperature sensor ADC output
    reg [2:0] wash_mode;  //wash mode for the wm
    reg change_temperature;
    reg change_spin_speed;
    reg [9:0] water_level_sensor; //sensor for water level
    reg [9:0] motor_speed_sensor;
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
        .load_weight(load_weight),
        .vibration_sensor(vibration_sensor),
        .temperature_adc_sensor(temperature_adc_sensor),
        .wash_mode(wash_mode),
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
        forever
        #1 clk = ~clk;
    end

endmodule