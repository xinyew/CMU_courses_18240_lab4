`default_nettype none

module tb();
  logic [7:0] D;
  logic [511:0] Q;
  logic en, load, clock;

  LeftShift8Register DUT (.*);

  initial begin
      clock = 1;
      forever #10 clock = ~clock;
  end

  initial begin
      $monitor($time,, "D: %x | Q: %x", D, Q);
  end

  initial begin
      D <= 8'h11;
      en <= 1;
      @(posedge clock);
      load <= 0;
      @(posedge clock);
      @(posedge clock);
      @(posedge clock);
      @(posedge clock);
      @(posedge clock);
      D <= 8'hFF;
      @(posedge clock);
      @(posedge clock);
      #1 $finish;
  end
endmodule : tb
