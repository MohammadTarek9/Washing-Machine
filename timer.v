module timer (clk, reset, enable, clk_freq, timer_period, done);
    input clk, reset, enable;
    input [15:0] clk_freq, timer_period;
    output done;
    //Total number of ticks to reach
    wire[31:0] count_max;
    assign count_max = clk_freq * timer_period;
    //Placeholder for done to use in procedure
    reg done_reg = 0;
    assign done = done_reg;
    
    reg [31:0] counter = 0;
    
    always @(posedge clk, posedge reset) begin
        if (enable) begin
            if (reset) begin
                counter = 0;
                done_reg = 0;
            end
            else if (counter === count_max) begin
                done_reg = 1;
                counter = 0;
            end
            else begin
                counter = counter + 1;
            end
        end
    end
endmodule