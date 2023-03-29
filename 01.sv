`default_nettype none

module Receiver
    (input logic clock, reset, serialIn,
     output logic [7:0] messageByte,
     output logic isNew);

    logic is2bitErr, fs_error, done;
    // for Shift Register
    logic S_en;
    // for Out Register
    logic R_en, R_clear;
    // for Cycle Counter
    logic C_en, C_clear;
    logic [3:0] C_count;
    // for Error Counter
    logic E_en, E_clear;
    logic [3:0] E_count;
    logic [7:0] mux_out;
    logic [12:0] received_message, sm;
    logic [1:0] state, n_state;

    fsm control(.*);
    ShiftRegister_SIPO #(13) reg1 (.serial(serialIn),
                                   .en(S_en), 
                                   .left(1), 
                                   .clock(clock), 
                                   .Q(received_message));

    SECDEDdecoder dec1 (.inCode(received_message), 
                        .is2BitErr(is2bitErr), 
                        .outCode(sm));

    Counter counter1 (.en(C_en), .clear(C_clear), .up(1),
                    .clock(clock), .Q(C_count));

    Counter counter2 (.en(E_en), .clear(E_clear), .up(1),
                    .clock(clock), .Q(E_count));

    Comparator comp1 (.A(C_count), .B(4'd12), .AeqB(done));

    Comparator comp2 (.A(E_count), .B(4'd11), .AeqB(fs_error));

    Mux2to1 m1 (.I0({sm[12], sm[11], sm[10], sm[9], 
                     sm[7], sm[6], sm[5], sm[3]}),
                .I1(8'h15), .S(is2bitErr | fs_error), .Y(mux_out));

    Register reg2 (.en(R_en), .clear(R_clear), .clock(clock),
                .D(mux_out), .Q(messageByte));

endmodule : Receiver

module fsm
    (input logic clock, serialIn, reset, done, fs_error,
     output logic S_en, R_en, R_clear, C_en, C_clear, E_en, E_clear);

    enum logic [1:0] { 
                       idle = 2'b00, 
                       running = 2'b01, 
                       completed = 2'b10, 
                       error = 2'b11
                       } state, n_state;

    always_ff @(posedge clock) begin
        if (reset)
            state <= idle;
        else
            state <= n_state;
    end

     always_comb begin
        case(state)
            idle : begin
                if(fs_error)
                    n_state = error;
                else if(serialIn)
                    n_state = running;
                else if(~serialIn)
                    n_state = idle;

                S_en = 0;
                // loop counter signal
                C_en = 0;
                C_clear = 1;
                // error counter signal
                E_en = 1;
                E_clear = 0;
                // register signal
                R_en = 0;
                R_clear = 0;
            end

            running : begin
                n_state = (done) ? completed : running;
                S_en = 1;
                C_en = 1;
                R_en = 0;
                R_clear = 0;
                E_en = 0;
                E_clear = 1;
                C_clear = 0;
            end

            completed : begin
                n_state = (serialIn) ? error : idle;
                S_en = 0;
                C_en = 0;
                R_en = 1;
                R_clear = 0;
                E_en = 0;
                E_clear = 1;
                C_clear = 1;
            end
            error : begin
                n_state = idle;
                S_en = 0;
                C_en = 0;
                R_en = 1;
                R_clear = 0;
                E_en = 0;
                E_clear = 1;
                C_clear = 1;
            end
        endcase
     end
endmodule : fsm
