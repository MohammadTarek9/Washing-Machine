`timescale 100ms / 100ms
module spin_speed_tb();
    reg clk;
    reg reset;
    reg [2:0] wash_mode;
    reg increment;
    wire [10:0] selected_spin_speed;
    integer i, j;
    spin_speed_incrementor_lut dut(
        .clk(clk),
        .reset(reset),
        .wash_mode(wash_mode),
        .increment(increment),
        .selected_spin_speed(selected_spin_speed)
    );

    initial begin
    clk = 0;
    forever begin
        #1 clk = ~clk;
    end
    end

    initial begin
        //$dumpfile("spin_speed_tb.vcd");
        $dumpvars(0, spin_speed_tb);
        //checking that it correctly selects speed for each mode and can increment
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
        //checking that it can correctly increment between all spin speeds
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
        #4 $stop;
    end
           
    initial begin
        $monitor("Time=%t, reset=%b, wash_mode=%b, increment=%b, selected_spin_speed=%d", $time, reset, wash_mode, increment, selected_spin_speed);
    end
endmodule