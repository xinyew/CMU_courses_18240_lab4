`default_nettype none

module testbench();
  logic clock, CLOCK_50, reset, data;

  Sender S (.clock(clock),
            .reset(reset),
            .serialOut(data));

  logic [511:0] byteOut;
  logic isNew;
  task2 R (.clock(CLOCK_50),
              .reset(reset),
              .serialIn(data),
              .messageBytes(byteOut),
              .isNew(isNew));

  initial begin
    clock = 1'b0;
    reset = 1'b1;
    forever #159 clock = ~clock;
  end

  initial begin
    CLOCK_50 = 1'b0;
    forever #4 CLOCK_50 = ~CLOCK_50;
  end

  initial begin
    $monitor($time,, "%10s %10s  Char: %x String: %s", R.control.state.name, R.control.n_state.name, R.m1.Y ,byteOut);
    //$monitor($time,, "Char: %c", byteOut);
    @(posedge clock);
    reset <= 0;
    @(posedge clock);
  #10000000 $finish;
  end
endmodule : testbench
