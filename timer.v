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
//ensure when reset is high, counter is reset to 0
/*
psl default clock=rose(clk);
psl property RESET_COUNTER = always (reset==1 -> next(counter==0));
psl assert RESET_COUNTER;
*/
//ensure when reset is high, done is reset to 0
/*
psl property RESET_DONE = always (reset==1 -> next(done==0));
psl assert RESET_DONE;
*/
//ensure when counter reaches count_max, done is set to 1
/*
psl property DONE_SET = always ((counter==count_max && !reset && enable) -> next(done==1));
psl assert DONE_SET;
*/
//ensure when counter is less than count_max, counter is incremented
/*
psl property COUNTER_INCREMENT = always ((counter<count_max && !reset && enable) -> next(counter==prev(counter)+1'b1));
psl assert COUNTER_INCREMENT;
*/
endmodule