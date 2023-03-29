`default_nettype none
module chipInterface(
    input logic CLOCK_50,
    input logic [17:0] SW,
    input logic UART_RXD,
    input logic[3:0] KEY,
    output logic [6:0] HEX7, HEX6
);
    // here we declare the output
    logic [511:0] m; // this should be connected to out
    logic [7:0] curr_add; // this will be our connection to out
    // here we declare counter vars
    logic c_clr, c_en, isNew;
    logic click, reset;
    // Assigning the FPGA inputs
    assign reset = ~KEY[2];
    assign click = ~KEY[3];

    // here we declare our receiver
    task2 R (.clock(CLOCK_50),
              .reset(reset),
              .serialIn(UART_RXD),
              .messageBytes(m),
              .isNew(isNew));

    // here we declare the counter
    select s (.bits(m),
              .addr({}));

endmodule : chipInterface

module select
 (input logic [511:0] bits,
  input logic [7:0] addr,
  output logic [63:0] out);

  assign out = bits[addr+63+:64];

endmodule : select

