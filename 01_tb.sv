`default_nettype none

module testbench();
  logic clock, reset, data;

  Sender S (.clock(clock),
            .reset(reset),
            .serialOut(data));

  logic [7:0] byteOut;
  logic isNew;
  Receiver R (.clock(clock),
              .reset(reset),
              .serialIn(data),
              .messageByte(byteOut),
              .isNew(isNew));

  initial begin
    clock = 0;
    reset = 1;
    forever #10 clock = ~clock;
  end

  initial begin
    $monitor($time,, "%8s %8s Mux: %b Char: %h %s %b %b", 
    R.control.state.name, R.control.n_state.name, R.reg1.Q, 
    byteOut, byteOut, R.fs_error, R.is2bitErr);
    @(posedge clock);
    reset <= 0;
    @(posedge clock);
  #25000 $finish;
  end
endmodule : testbench
