module SECDEDdecoder
    (input logic [12:0] inCode,
    output logic [3:0] syndrome,
    output logic is1BitErr, is2BitErr,
    output logic [12:0] outCode);

    // declare modules
    makeSyndrome m1(.cw(inCode), .syndrome(syndrome));
    makeIs1BitErr m2(.syndrome(syndrome), .is1BitErr(is1BitErr), 
                  .cw(inCode));
    makeIs2BitErr m4(.syndrome(syndrome), .is2BitErr(is2BitErr), 
                  .cw(inCode));
    makeCorrect m3(.codeWord(inCode), .syndrome(syndrome),
                 .is1BitErr(is1BitErr), .correctCodeWord(outCode));

endmodule : SECDEDdecoder

module makeSyndrome
    (input logic [12:0] cw,
    output logic [3:0] syndrome);
    assign syndrome[0] = cw[1]^cw[3]^cw[5]^cw[7]^cw[9]^cw[11];
    assign syndrome[1] = cw[2]^cw[3]^cw[6]^cw[7]^cw[10]^cw[11];
    assign syndrome[2] = cw[4]^cw[5]^cw[6]^cw[7]^cw[12];
    assign syndrome[3] = cw[8]^cw[9]^cw[10]^cw[11]^cw[12];
endmodule : makeSyndrome

module makeCorrect
    (input logic [12:0] codeWord,
    input logic [3:0] syndrome,
    input logic is1BitErr,
    output logic [12:0] correctCodeWord);

    assign correctCodeWord = (is1BitErr) ? 
        codeWord ^ (13'b1 << syndrome) : codeWord;
endmodule : makeCorrect

module makeGlobalParity(
    input logic [12:0] cw,
    output logic globalParity);
    assign globalParity = cw[0]^cw[1]^cw[2]^cw[3]^cw[4]^cw[5]^cw[6] ^
                          cw[7]^cw[8]^cw[9]^cw[10]^cw[11]^cw[12];
                        
endmodule : makeGlobalParity

module makeIs1BitErr
    (input logic  [3:0] syndrome,
     input logic [12:0] cw,
     output logic is1BitErr);

    logic globalParity;
    makeGlobalParity m(.cw(cw), .globalParity(globalParity));
    
    assign is1BitErr = (globalParity) ? 1 : 0;

endmodule : makeIs1BitErr

module makeIs2BitErr
    (input logic  [3:0] syndrome,
     input logic [12:0] cw,
     output logic is2BitErr);

    logic globalParity;
    makeGlobalParity m(.cw(cw), .globalParity(globalParity));
    
    always_comb begin
        is2BitErr = 0;
        if(globalParity == 0) begin
            if(syndrome != 0) begin
                is2BitErr = 1;
            end
            else
                is2BitErr = 0;
        end
    end
endmodule : makeIs2BitErr

