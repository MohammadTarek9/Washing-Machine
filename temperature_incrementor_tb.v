`timescale 100ms / 100ms
module temperature_incrementor_tb();
    reg clk;
    reg reset;
    reg [2:0] wash_mode;
    reg increment;
    wire [5:0] selected_temperature;
    reg [3:0] i;
    temperature_incrementor_lut dut(
        .clk(clk),
        .reset(reset),
        .wash_mode(wash_mode),
        .increment(increment),
        .selected_temperature(selected_temperature)
    );

    initial begin
    clk = 0;
    forever begin
        #1 clk = ~clk;
    end
    end

    initial begin
        //$dumpfile("temperature_incrementor_tb.vcd");
        $dumpvars(0, temperature_incrementor_tb);
        //checking that incrementing to the next temperature works correctly and correctly selected for each wash mode
        reset = 1;
        increment = 0;
        wash_mode = 3'd0;
        #2 for (i = 0; i < 8; i = i + 1) begin
            #2 wash_mode = i;
            increment = $unsigned($random) % 2;
            reset = 0;
            #2 increment = 0;
            #2 reset = 1;
            #2 reset = 0;
            end
        //checking that it can increment through all temperatures
        #2 increment = 0;
        #2
        reset=1;
        wash_mode=3'd3;
        #2
        reset=0;
        increment=1;
        #2
        increment=0;
        #2
        increment=1;
        #2
        increment=0;
        #2
        increment=1;
        #2
        increment=0;
        #2
        increment=1;
        #2
        increment=0;
        #2
        increment=1;
        #2
        increment=1;
        #2
        increment=1;
        #2
        increment=1;
        #2
        increment=1;
        #4 $stop;
    end
           
    initial begin
        $monitor("Time=%d, reset=%d, wash_mode=%d, increment=%d, index=%d", $time, reset, wash_mode, increment, dut.index);
    end
endmodule