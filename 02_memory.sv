`default_nettype none

module BusDriver
 #(parameter WIDTH = 8)
  (input  logic en,
   input  logic [WIDTH-1:0] data,
   output logic [WIDTH-1:0] buff,
   inout  tri   [WIDTH-1:0] bus
   );

   assign bus = (en) ? data : 'bz;
   assign buff = bus;

endmodule : BusDriver

module Memory
 #(parameter DW = 16,
             W  = 256,
             AW = $clog2(W))
  (input  logic re, we, clock,
   input  logic [AW-1:0] addr,
   inout  tri   [DW-1:0] data);

  logic [DW-1:0] M[W];
  logic [DW-1:0] rData;

  assign data = (re) ? rData : 'bz;

  always_ff @(posedge clock)
    if (we)
      M[addr] <= data;

  always_comb
    rData = M[addr];

endmodule : Memory
