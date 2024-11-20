`timescale 100ms / 100ms
module load_size_tb;

// ports
reg clk;
reg reset;
reg [7:0] load_weight;

wire [9:0] water_level;


washing_machine_load_size_detection uut (
    .clk(clk),
    .reset(reset),
    .load_weight(load_weight),
    .water_level(water_level)
);

initial begin
    clk = 0;
    forever #1 clk = ~clk; 
end

// Test sequence
initial begin
        //$dumpfile("washing_machine_load_size_detection_tb.vcd");
        $dumpvars(0, load_size_tb);
    reset = 1;
    load_weight = 8'd0;
    #2 reset = 0;

    // Test Case 1: Low water level (load_weight <= LOW_THRESHOLD)
    #2 load_weight = 8'd10; // 00001010
    #2; // Wait and check water_level output

    // Test Case 2: Medium water level (LOW_THRESHOLD < load_weight <= MEDIUM_THRESHOLD)
    #2 load_weight = 8'd30; // 00011110
    #2; // Wait and check water_level output

    // Test Case 3: High water level (MEDIUM_THRESHOLD < load_weight <= HIGH_THRESHOLD)
    #2 load_weight = 8'd60; // 00111100
    #2; // Wait and check water_level output

    // Test Case 4: Extra High water level (load_weight > HIGH_THRESHOLD)
    #2 load_weight = 8'd90; // 01011010
    #2; // Wait and check water_level output

    // Test Case 5: (load_weight = LOW_THRESHOLD)
    #2 load_weight = 8'd20; // 00010100
    #2; // Wait and check water_level output

    // Test Case 6:  (load_weight = MEDIUM_THRESHOLD)
    #2 load_weight = 8'd50; // 00110010
    #2; // Wait and check water_level output

    // Test Case 7:  (load_weight = HIGH_THRESHOLD)
    #2 load_weight = 8'd80; // 01010000
    #2; // Wait and check water_level output

    // Test Case 8: Medium load weight
    #2 load_weight = 8'd25; // 00011001
    #2; // Wait and check water_level output

    // Additional Test Case 9: Toggle all bits
    #2 load_weight = 8'd255; // 11111111
    #2; // Wait and check water_level output

    // Additional Test Case 10: Toggle all bits back to 0
    #2 load_weight = 8'd0; // 00000000
    #2; // Wait and check water_level output

     #4 $stop;      
     end

    // Monitor the signals and print values during simulation
    initial begin
        $monitor("Time=%t, reset=%b, load_weight=%d, water_level=%d", $time, reset, load_weight, water_level);
    end
endmodule
