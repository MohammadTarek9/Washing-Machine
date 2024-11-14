`timescale 100ms / 100ms
module temperature_incrementor_tb();
    reg clk;
    reg reset;
    reg [2:0] wash_mode;
    reg increment;
    wire [6:0] selected_temperature;
    integer i, j;
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
        reset = 1;
        increment = 0;
        wash_mode = 3'd0;
        #2 for (i = 0; i < 8; i = i + 1) begin
            wash_mode = i;
            for (j = 0; j < 2; j = j + 1) begin
            increment = j;
            reset = 0;
            #2 reset = 1;
            #2;
            end
        end
        #4 $stop;
    end
           
    initial begin
        $monitor("Time=%t, reset=%b, wash_mode=%b, increment=%b, selected_temperature=%d", $time, reset, wash_mode, increment, selected_temperature);
    end
endmodule