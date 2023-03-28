`default_nettype none

module task2
    (input logic clock, reset, serialIn,
     output logic [7:0] messageByte,
     output logic isNew);

    // 2bitErr, frame errer at beginnings,
    logic is2bitErr, fs_error, blockReceived;
    // time to sample, time to sample next bit;
    logic timeToSample, timeNextBit;

    // for Shift Register
    logic S_en; // enale shifting

    // for Out Register
    logic R_en, R_clear;

    // for Cycle Counter(13-bit output)
    logic C_en, C_clear;
    logic [3:0] C_count;

    // for Error Counter(detect fs_error)
    logic E_en, E_clear;
    logic [3:0] E_count;

    // for Sample counter(detect synced timing for sampling)
    logic A_en, A_clear;
    logic [2:0] A_count;

    // for Wait counter(detect 16 clock cycles to sample next)
    logic W_en, W_clear;
    logic [3:0] W_count;

    // if fs_error or is2BitErr, output 'h15;
    logic [7:0] mux_out;

    // uncorrected message, corrected message
    logic [12:0] uncorrected, corrected;

    // states
    logic [1:0] state, n_state;

    // FSM for the module
    fsm control(.*);

    // shift reg to collect bits
    ShiftRegister_SIPO #(13) reg1 (.serial(serialIn),
                .en(S_en), .left(1), .clock(clock), .Q(uncorrected));

    // corrector
    SECDEDdecoder dec1 (.inCode(uncorrected), .is2BitErr(is2bitErr), .outCode(corrected));

    // Count whether 13-bit block is received
    Counter counter1 (.en(C_en), .clear(C_clear), .up(1),
                    .clock(clock), .Q(C_count));

    // Count whether a beginning frame error occurs
    Counter counter2 (.en(E_en), .clear(E_clear), .up(1),
                    .clock(clock), .Q(E_count));

    // Count synced timing for sampling
    Counter counter3 (.en(A_en), .clear(A_clear), .up(1),
                    .clock(clock), .Q(A_count));

    // Count wait cycles
    Counter counter4 (.en(W_en), .clear(W_clear), .up(1),
                    .clock(clock), .Q(W_count));

    Comparator comp1 (.A(C_count), .B(4'd12), .AeqB(blockReceived));

    Comparator comp2 (.A(E_count), .B(4'd10), .AeqB(fs_error));

    Comparator comp3 (.A(A_count), .B(3'd7), .AeqB(timeToSample));

    Comparator comp4 (.A(W_count), .B(4'd15), .AeqB(timeNextBit));

    Mux2to1 m1 (.I0({corrected[12], corrected[11], corrected[10], corrected[9], corrected[7], corrected[6], corrected[5], corrected[3]}),
                .I1(8'h15), .S(is2bitErr | fs_error), .Y(mux_out));

    Register reg2 (.en(R_en), .clear(R_clear), .clock(clock),
                .D(mux_out), .Q(messageByte));

endmodule : task2

module fsm
    (input logic clock, serialIn, reset, blockReceived, fs_error,
     output logic S_en, R_en, R_clear, C_en, C_clear, E_en, E_clear);

    enum logic [1:0] {idle = 2'b00, running = 2'b01, completed = 2'b10, error = 2'b11} state, n_state;

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
                n_state = (blockReceived) ? completed : running;
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
