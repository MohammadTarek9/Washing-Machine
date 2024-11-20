module MainController(
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
    output cycle_complete_led,    // LED indicator for cycle complete
    output door_lock,
    output water_valve,
    output detergent_valve,
    output heater,
    output drain_pump,
    output [10:0] drum_motor,  
    output water_flow_error_led,   // LED indicator for water flow error
    output drainage_error_led,     // LED indicator for drainage error
    output vibration_error_led   // LED indicator for vibration error
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

parameter [6:0] GENERAL_WATER_LEVEL=7'd100;
  

wire timer_enable; //it is wire in the timer
wire timer_reset;
wire timer_done;
reg [3:0] clk_freq = 4'd5;  //5Hz
wire [3:0] timer_period; //changes with every state

wire temp_reset;
wire speed_reset;

// Declare signals for WaterFlowMonitor integration
wire water_flow_error;
wire water_flow_mode;
wire water_flow_reset;


wire [9:0] water_level; 
wire [5:0] selected_temperature;
wire [10:0] selected_spin_speed;


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
WashingMachineFSM fsm_inst (
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
    .detergent_valve(detergent_valve),
    .heater(heater),
    .drain_pump(drain_pump),
    .drum_motor(drum_motor),
    .water_flow_error_led(water_flow_error_led),
    .drainage_error_led(drainage_error_led),
    .vibration_error_led(vibration_error_led)
);
//ensure that pause works correctly with timer
/*
    psl default clock=rose(clk);
    psl property MAINPAUSE = always (pause -> next(timermod.counter==prev(timermod.counter)));
    psl assert MAINPAUSE;
*/
//ensure that door is locked when start
/*
    psl property DOOR_LOCK = always ((fsm_inst.current_state==fsm_inst.START && fsm_inst.start==1 && fsm_inst.door_locked==1 && fsm_inst.clothes_loaded==1) -> door_lock==1);
    psl assert DOOR_LOCK;
*/
//ensure that heater is turned on when heat fill
/*
    psl property HEATER_ON = always ((fsm_inst.current_state==fsm_inst.HEAT_FILL && fsm_inst.temperature_adc_sensor<fsm_inst.selected_temperature) -> heater==1);
    psl assert HEATER_ON;
*/
//ensure that water valve is turned on when fill initial or fill before rinse
/*
    psl property WATER_VALVE_ON = always ((fsm_inst.current_state==fsm_inst.FILL_INITIAL || fsm_inst.current_state==fsm_inst.FILL_BEFORE_RINSE) -> water_valve==1);
    psl assert WATER_VALVE_ON;
*/
//ensure that water valve turned on in heat fill
/*
    psl property WATER_VALVE_ON2 = always ((fsm_inst.current_state==fsm_inst.HEAT_FILL && fsm_inst.water_level_sensor<fsm_inst.water_level) -> water_valve==1);
    psl assert WATER_VALVE_ON2;
*/
//ensure that detergent valve turned on in heat fill
/*
    psl property DETERGENT_VALVE_ON = always ((fsm_inst.current_state==fsm_inst.HEAT_FILL && fsm_inst.water_level_sensor<fsm_inst.water_level) -> detergent_valve==1);
    psl assert DETERGENT_VALVE_ON;
*/
//ensure that water flow mode is filling in all filling states
/*
    psl property FILLING_MODE = always ((fsm_inst.current_state==fsm_inst.FILL_INITIAL || fsm_inst.current_state==fsm_inst.HEAT_FILL || fsm_inst.current_state==fsm_inst.FILL_BEFORE_RINSE) -> water_flow_mode==1);
    psl assert FILLING_MODE;
*/
//ensure that water flow mode is draining in all draining states
/*
    psl property DRAINING_MODE = always ((fsm_inst.current_state==fsm_inst.DRAIN_AFTER_WASH || fsm_inst.current_state==fsm_inst.DRAIN_AFTER_RINSE) -> water_flow_mode==0);
    psl assert DRAINING_MODE;
*/
//ensure that drain pump is on in all draining states
/*
    psl property DRAIN_PUMP_ON = always (((fsm_inst.current_state==fsm_inst.DRAIN_AFTER_WASH || fsm_inst.current_state==fsm_inst.DRAIN_AFTER_RINSE) && fsm_inst.water_level_sensor!=0) -> drain_pump==1);
    psl assert DRAIN_PUMP_ON;
*/
//ensure that drum motor is assigned to the selected spin speed in wash, rinse, and dry spin
/*
    psl property DRUM_MOTOR_ON = always ((fsm_inst.current_state==fsm_inst.WASH || fsm_inst.current_state==fsm_inst.RINSE || fsm_inst.current_state==fsm_inst.DRY_SPIN) -> drum_motor==fsm_inst.selected_spin_speed);
    psl assert DRAIN_PUMP_ON;
*/
//ensure that cycle complete led is on when cycle is complete
/*
    psl property CYCLE_COMPLETE = always ((fsm_inst.current_state==fsm_inst.COMPLETE) -> cycle_complete_led==1);
    psl assert CYCLE_COMPLETE;
*/
//ensure that vibration error led is on when vibration sensor is on
/*
    psl property VIBRATION_ERROR = always ((fsm_inst.vibration_sensor==1) -> next(vibration_error_led==1));
    psl assert VIBRATION_ERROR;
*/
endmodule