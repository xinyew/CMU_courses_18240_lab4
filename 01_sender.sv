/*
 * Lab 3a: Transmitter, Task1
 *
 */

module Sender(
  input  logic clock, reset,
  output logic serialOut);

  parameter WORDS = 25, WORD_SIZE = 64;
  logic [WORD_SIZE-1:0] message_rom [WORDS-1:0];
  logic [12:0] word_counter;
  logic [5:0] bit_counter;

  initial begin
    $readmemb("01.vm", message_rom);
  end

  always_ff @(posedge clock, posedge reset) begin
    if (reset) begin
      serialOut <= 0;
      word_counter <= 0;
      bit_counter <= WORD_SIZE - 1;
    end
    else begin
      if (word_counter < WORDS)
        serialOut <= message_rom[word_counter][bit_counter];
      else
        serialOut <= 0;

      if (bit_counter == 0) begin
        bit_counter = WORD_SIZE -1;
        word_counter = word_counter + 1;
      end else
        bit_counter = bit_counter - 1;
    end
  end

endmodule : Sender
