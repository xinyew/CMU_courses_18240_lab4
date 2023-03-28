`default_nettype none
// this is a test bench for out clock divider

module clock_divider_test();
    // declare the variables
    logic en, reset, clear, clock, new_clock;

    // here we make the clock run at 50 Mhz
    initial begin 
        clock = 0;
        forever #2ns clock = ~clock;
    end

    // here we declare the clock_divider module
    clock_divider #(5) dut(.*);    

    // begin test_bench
    initial begin
        reset = 1;
        en = 1;
        clear = 1;
        #1ns;
        clear = 0;
        reset = 0;
        $monitor($time,, "new clock: %b", new_clock);
        #10ms;
        $finish;
    end

endmodule: clock_divider_test
