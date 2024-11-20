module timer (clk, reset, enable, clk_freq, timer_period, done);
    input clk, reset, enable;
    input [3:0] clk_freq, timer_period;
    output reg done = 0;
    //Total number of ticks to reach
    wire[7:0] count_max;
    assign count_max = clk_freq * timer_period;
    
    reg [7:0] counter = 0;
    
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter = 0;
            done = 0;
        end
        else if (enable) begin
            if (counter === count_max) begin
                done = 1;
                counter = 0;
            end
            else begin
                counter = counter + 1;
            end
        end
    end

endmodule