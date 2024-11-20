`timescale 100ms/100ms
module timerrand_tb();
//Ports declaration
reg clk, reset, enable;
reg[3:0] clk_freq, timer_period;
wire done;

// Design instantiation
timer dut(clk, reset, enable, clk_freq, timer_period, done);

//Creating clock
initial begin
    clk = 0; //check this
    forever begin
        #1 clk = ~clk;
    end
end

// driving dut inputs
initial begin
    enable = 0;
    reset = 0;
    clk_freq = 4'd5;
    timer_period = 4'd1;
    #2 enable = 1'b1;
    #2 enable = 0;
    #2 reset = 1'b1;
    #2 enable = 1;
    #2 reset=1'b0;
    #25
    #2 enable = 0;
    #2 reset=1'b1;
    #2
    repeat(20) begin
        #2 enable=1'b0;
        #2 reset=1'b0;
        clk_freq = (($unsigned($random)) % 15) + 1;
        timer_period = (($unsigned($random)) % 15) + 1;
        #2 enable=1'b1;
        #2 enable = 0;
        #2 reset=1'b1;
        #2 enable = 1;
        #2 reset=1'b0;
        #((clk_freq * timer_period*2)+5);
        enable = 0;
        #2 reset=1'b1;
    end
    #25 $stop;
end

endmodule
