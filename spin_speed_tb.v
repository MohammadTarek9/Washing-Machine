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
        $monitor("Time=%t, reset=%b, wash_mode=%b, increment=%b, selected_spin_speed=%d", $time, reset, wash_mode, increment, selected_spin_speed);
    end
endmodule