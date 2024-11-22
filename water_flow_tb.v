`timescale 100ms / 100ms

module water_flow_tb;

    // ports
    reg clk;
    reg reset;
    reg [9:0] water_level_sensor;
    reg mode; // 1 for filling, 0 for draining
    
    wire error_flag;

    WaterFlowMonitor uut (
        .clk(clk),
        .reset(reset),
        .water_level_sensor(water_level_sensor),
        .mode(mode),
        .error_flag(error_flag)
    );

    // Clock signals , same for all the tb modules after 5ms
    initial begin
        clk = 0;
        forever #1 clk = ~clk; 
    end

    // Test sequence
    initial begin
	//$dumpfile("WaterFlowMonitor_tb.vcd");
        $dumpvars(0, water_flow_tb);
        reset = 1;
        mode = 1;                // Start with filling mode
        water_level_sensor = 10'd50; // Initial water level
        #2 reset = 0;           // Release reset

        // 1. Test normal operation in filling mode
        // Expect no error, water level should increase
        repeat(5) begin
            #2 water_level_sensor = water_level_sensor + 10'd20; // Increase water level
        end
        // 2. Test insufficient increase in filling mode
        // Hold water level constant to trigger error flag
        #2 water_level_sensor = water_level_sensor;
        #20; // Wait for TIME_LIMIT cycles (adjust based on TIME_LIMIT value in module)
        //$display("Error Flag (Filling mode, no increase): %d", error_flag);
        // 3. Switch to draining mode and reset
        reset = 1;
        #2 reset = 0;
        mode = 0;               // Set mode to draining
        #2 reset = 1;
        water_level_sensor = 10'd200; // New starting water level
        #2 reset = 0;
        // 4. Test normal operation in draining mode
        repeat(5) begin
            #2 water_level_sensor = water_level_sensor - 10'd20; // Decrease water level
        end
        // 5. Test insufficient decrease in draining mode
        #2 water_level_sensor = water_level_sensor;
        #20; // Wait for TIME_LIMIT cycles
        //$display("Error Flag (Draining mode, no decrease): %d", error_flag);

        // 6. Test mode change handling
        reset = 1;
        #2 reset = 0;
        mode = 1;                // Switch back to filling mode
        water_level_sensor = 10'd50; // Reset water level for filling mode
        repeat(10) begin
            #2 water_level_sensor = water_level_sensor + 10'd5; // Increase water level by less than THRESHOLD
        end
        //#2 water_level_sensor = water_level_sensor + 10'd15; // Increment by less than THRESHOLD
        //#20; // Wait for TIME_LIMIT cycles
        //$display("Error Flag (Filling mode, insufficient increment): %d", error_flag);
        #2 reset=1;
        mode=0;
        water_level_sensor=10'd200;
        #2 reset=0;
        repeat(10) begin
            #2 water_level_sensor = water_level_sensor - 10'd5; // Decrease water level by less than THRESHOLD
        end
        //testing that both modes work together
        #2 reset=1;
        mode=1;
        water_level_sensor = 10'd60;
        repeat(5) begin
            #2 water_level_sensor = water_level_sensor + 10'd20; // Increase water level
        end
        #2 reset=1;
        #2 reset=0;
        mode=0;
        repeat(5) begin
            #2 water_level_sensor = water_level_sensor - 10'd20; // Decrease water level
        end
        //high water level sensors
        #2 water_level_sensor = 10'd800;
        repeat(5) begin
            #2 water_level_sensor = water_level_sensor - 10'd20; // Derease water level
        end
        reset = 1;
       #4 $stop;
    end
   initial begin
        $monitor("reset=%b, previous=%d, water_level_sensor=%d, error_flag=%b, counter=%d", 
                 reset, uut.previous_level, water_level_sensor, error_flag, uut.counter);
    end
endmodule
