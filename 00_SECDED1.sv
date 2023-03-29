`default_nettype none

// Top-level module
module SECDEDdecoder

  (input logic [12:0] inCode,
   output logic [3:0] syndrome,
   output logic is1BitErr, is2BitErr,
   output logic [12:0] outCode);

  makeSyndrome mS (.codeWord(inCode),
                    .syndrome(syndrome));

  logic [12:0] correctCodeWord;
  makeCorrect mC (.codeWord(inCode),
                  .syndrome(syndrome),
                  .correctCodeWord(correctCodeWord));
  logic globalErr;
  checkGlobal cG (.codeWord(inCode),
                  .globalErr(globalErr));
  logic cleanSyndrome;
  makeCleanSyndrome mCS (.syndrome(syndrome),
                         .cleanSyndrome(cleanSyndrome));

  check1BitErr c1 (.globalErr(globalErr),
                   .cleanSyndrome(cleanSyndrome),
                   .is1BitErr(is1BitErr));
  check2BitErr c2 (.globalErr(globalErr),
                   .cleanSyndrome(cleanSyndrome),
                   .is2BitErr(is2BitErr));
  outputPicker oP (.codeWord(inCode),
                   .correctCodeWord(correctCodeWord),
                   .is1BitErr(is1BitErr),
                   .codeOut(outCode));


endmodule: SECDEDdecoder

// Module that checks whether
// the syndrome bits are all 0s
module makeCleanSyndrome
  (input logic [3:0] syndrome,
   output logic cleanSyndrome);

  assign cleanSyndrome = syndrome[0] | syndrome[1]
                       | syndrome[2] | syndrome[3];

endmodule

// Module that outputs the syndrome
module makeSyndrome
  (input logic [12:0] codeWord,
   output logic [3:0] syndrome);

  // Syndrome[0]
  xor (syndrome[0], codeWord[1], codeWord[3],
       codeWord[5], codeWord[7], codeWord[9], codeWord[11]);

  // Syndrome[1]
  xor (syndrome[1], codeWord[2], codeWord[3],
       codeWord[6], codeWord[7], codeWord[10], codeWord[11]);

  // Syndrome[2]
  xor (syndrome[2], codeWord[4], codeWord[5],
       codeWord[6], codeWord[7], codeWord[12]);

  // Syndrome[3]
  xor (syndrome[3], codeWord[8], codeWord[9],
       codeWord[10], codeWord[11], codeWord[12]);

endmodule: makeSyndrome

module makeCorrect
  (input logic [12:0] codeWord,
   input logic [3:0] syndrome,
   output logic [12:0] correctCodeWord);

  logic [12:0] mask;

  always_comb begin
    mask = 13'd1;
    mask = mask << syndrome;
    correctCodeWord = codeWord;
    correctCodeWord = correctCodeWord ^ mask;
  end

endmodule: makeCorrect

// Module to check global parity
module checkGlobal
  (input logic [12:0] codeWord,
   output logic globalErr);

  assign globalErr = codeWord[0] ^ codeWord[1] ^ codeWord[2]
                   ^ codeWord[3] ^ codeWord[4] ^ codeWord[5]
                   ^ codeWord[6] ^ codeWord[7] ^ codeWord[8]
                   ^ codeWord[9] ^ codeWord[10] ^ codeWord[11]
                   ^ codeWord[12];

endmodule : checkGlobal

// Module to check for 1-bit error
module check1BitErr
  (input logic cleanSyndrome,
   input logic globalErr,
   output logic is1BitErr);

  always_comb begin
   if (globalErr == 1 && cleanSyndrome == 1)
     is1BitErr = 1;
   else
     is1BitErr = 0;
  end

endmodule : check1BitErr

// Module to check for 1-bit error
module check2BitErr
  (input logic cleanSyndrome,
   input logic globalErr,
   output logic is2BitErr);

  always_comb begin
    if (globalErr == 0 && cleanSyndrome == 1)
      is2BitErr = 1;
    else
      is2BitErr = 0;
  end

endmodule : check2BitErr

// Module to pick the correct output
module outputPicker
  (input logic [12:0] codeWord, correctCodeWord,
   input logic is1BitErr,
   output logic [12:0] codeOut);

  always_comb begin
    if (is1BitErr)
      codeOut = correctCodeWord;
    else
      codeOut = codeWord;
  end

endmodule : outputPicker