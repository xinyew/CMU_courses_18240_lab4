`default_nettype none

module task2
    (input logic clock, reset, serialIn,
     output logic [511:0] messageBytes,
     output logic isNew);

    // 2bitErr, frame errors
    logic is2bitErr, fs_error, fe_error;
    // time to sample, time to sample next bit;
    logic timeToSample, timeNextBit;
    // a block of 13bits received
    logic blockReceived;

    // for Shift Register
    logic S_en; // enale shifting

    // for Out Register
    logic R_en;

    // for Cycle Counter(13-bit output)
    logic C_en, C_clear;
    logic [31:0] C_count;

    // for Error Counter(detect fs_error)
    logic E_en, E_clear;
    logic [31:0] E_count;

    // for Sample counter(detect synced timing for sampling)
    logic A_en, A_clear;
    logic [31:0] A_count;

    // for Wait counter(detect 16 clock cycles to sample next)
    logic W_en, W_clear;
    logic [31:0] W_count;

    // for char counter(count char num received)
    logic Char_en, Char_clear;
    logic [31:0] Char_count;

    // if fs_error, fe_error or is2BitErr, output 'h15;
    logic [7:0] mux_out;

    // uncorrected message, corrected message
    logic [12:0] uncorrected, corrected;

    // FSM for the module
    fsm control(.*);

    // shift reg to collect bits
    ShiftRegister_SIPO #(13) reg1 (.serial(serialIn),
                .en(S_en), .left(1), .clock(clock), .Q(uncorrected));

    // corrector
    SECDEDdecoder dec1 (.inCode(uncorrected), .is2BitErr(is2bitErr), .outCode(corrected));

    // Count whether 13-bit block is received
    Counter #(32) counter1 (.en(C_en), .clear(C_clear), .up(1),
                    .clock(clock), .Q(C_count));

    // Count whether a beginning frame error occurs
    Counter #(32) counter2 (.en(E_en), .clear(E_clear), .up(1),
                    .clock(clock), .Q(E_count));

    // Count synced timing for sampling
    Counter #(32) counter3 (.en(A_en), .clear(A_clear), .up(1),
                    .clock(clock), .Q(A_count));

    // Count wait cycles
    Counter #(32) counter4 (.en(W_en), .clear(W_clear), .up(1),
                    .clock(clock), .Q(W_count));

    // Count how many chars receited
    Counter #(32) counter5 (.en(Char_en), .clear(Char_clear), .up(1),
                    .clock(clock), .Q(Char_count));

    // Count timings to generate real edges
    // Counter counter5 (.en(

    // whether a block is received
    Comparator #(32) comp1 (.A(C_count), .B(32'd13), .AeqB(blockReceived));

    // whether we get a frame error of 10 consecutive 0s
    Comparator #(32) comp2 (.A(E_count), .B(32'd47_700), .AeqB(fs_error));

    // whether it's time to sample after syncing 8 * 3975
    Comparator #(32) comp3 (.A(A_count), .B(32'd1_988), .AeqB(timeToSample));

    // whether it's time to sample without seeing an edge
    Comparator #(32) comp4 (.A(W_count), .B(32'd3_975), .AeqB(timeNextBit));

    // choose from corrected char or error code
    Mux2to1 m1 (.I0({corrected[12], corrected[11], corrected[10], corrected[9], corrected[7], corrected[6], corrected[5], corrected[3]}),
                .I1(8'h15), .S(is2bitErr | fs_error | fe_error), .Y(mux_out));

    // reg to store the result
    LeftShift8Register reg2 (.en(R_en), .clock(clock),
                .D(mux_out), .Q(messageBytes));

endmodule : task2

module fsm
    (input logic clock, serialIn, reset, timeToSample,
                 blockReceived, fs_error, timeNextBit, is2bitErr,
     output logic S_en, R_en, fe_error,
     output logic C_en, C_clear, E_en, E_clear, A_en, A_clear, W_en, W_clear, Char_en, Char_clear);

    enum logic [2:0] {IDLE = 3'b000, SYNC = 3'b001, SAMPLE = 3'b010, WAIT0 = 3'b011, WAIT1 = 3'b100, COMPLETED = 3'b101, ERROR = 3'b110} state, n_state;

    always_ff @(posedge clock, posedge reset) begin
        if (reset) begin
            state <= IDLE;
            Char_clear <= 1;
        end
        else begin
            state <= n_state;
            Char_clear <= 0;
        end
    end

    always_comb begin
        case(state)
            IDLE : begin
                fe_error = 0;
                if(fs_error)
                    n_state = ERROR;
                else if(serialIn)
                    n_state = SYNC;
                else
                    n_state = IDLE;

                // Do not shift
                S_en = 0;
                // keep clearing loop counter
                C_en = 0;
                C_clear = 1;
                // keep counting 0s in IDLE state
                E_en = 1;
                E_clear = 0;
                // do not count sampling timing after syncing
                A_en = 0;
                A_clear = 1;
                // do not wait for edges or next sampling timing without
                // syncing
                W_en = 0;
                W_clear = 1;
                // do not increase char count, and do not clear it
                Char_en = 0;
                // disable register
                R_en = 0;
            end

            SYNC : begin
                fe_error = 0;
                if (timeToSample)
                    n_state = SAMPLE;
                else
                    n_state = SYNC;
                // Do not shift
                S_en = 0;
                // Do not increase loop count and do not clear it
                C_en = 0;
                C_clear = 0;
                // keep clearning frame error counter
                E_en = 0;
                E_clear = 1;
                // start counting sampling timing after syncing
                A_en = 1;
                A_clear = 0;
                // do not wait for edges or next sampling timing without
                // syncing
                W_en = 0;
                W_clear = 1;
                // do not increase char count, and do not clear it
                Char_en = 0;
                // disable register
                R_en = 0;
            end

            SAMPLE : begin
                fe_error = 0;
                if (serialIn)
                  n_state = WAIT1;
                else
                  n_state = WAIT0;
                // Shift once
                S_en = 1;
                // Increase num of bit collected by 1
                C_en = 1;
                C_clear = 0;
                if (blockReceived) 
                  n_state = COMPLETED;
                // keep clearning frame error counter
                E_en = 0;
                E_clear = 1;
                // clearing counting sampling timing after syncing
                A_en = 0;
                A_clear = 1;
                // do not wait for next sampling timing without
                // syncing
                W_en = 0;
                W_clear = 1;
                // do not increase char count, and do not clear it
                Char_en = 0;
                // disable register
                R_en = 0;
            end

            WAIT0 : begin
                fe_error = 0;
                if (serialIn)
                  n_state = SYNC;
                else if (timeNextBit)
                  n_state = SAMPLE;
                else
                  n_state = WAIT0;
                // Stop shifting
                S_en = 0;
                // Stop counting loop counter, do not clear
                C_en = 0;
                C_clear = 0;
                // keep clearing frame error counter
                E_en = 0;
                E_clear = 1;
                // Stop counting sampling timing and clear it
                A_en = 0;
                A_clear = 1;
                // Counting next sampling timing without syncing
                W_en = 1;
                W_clear = 0;
                // do not increase char count, and do not clear it
                Char_en = 0;
                // disable register
                R_en = 0;
            end

            WAIT1 : begin
                fe_error = 0;
                if (~serialIn)
                  n_state = SYNC;
                else if (timeNextBit)
                  n_state = SAMPLE;
                else
                  n_state = WAIT1;
                // Stop shifting
                S_en = 0;
                // Stop counting loop counter, do not clear
                C_en = 0;
                C_clear = 0;
                // keep clearing frame error counter
                E_en = 0;
                E_clear = 1;
                // Stop counting sampling timing and clear it
                A_en = 0;
                A_clear = 1;
                // Counting next sampling timing without syncing
                W_en = 1;
                W_clear = 0;
                // do not increase char count, and do not clear it
                Char_en = 0;
                // disable register
                R_en = 0;
            end

            COMPLETED : begin
                if (~timeNextBit) begin
                  n_state = COMPLETED;
                  fe_error = 0;
                  R_en = 0;
                  Char_en = 0;
                  W_en = 1;
                  W_clear = 0;
                end
                else if (is2bitErr || serialIn) begin
                  n_state = ERROR;
                  fe_error = 1;
                  R_en = 1;
                  Char_en = 1;
                  W_en = 0;
                  W_clear = 1;
                end
                else begin
                  n_state = IDLE;
                  fe_error = 0;
                  R_en = 1;
                  Char_en = 1;
                  W_en = 1;
                  W_clear = 0;
                end
                // Stop shifting
                S_en = 0;
                // Stop counting loop counter, clear it
                C_en = 0;
                C_clear = 1;
                // keep clearing frame error counter
                E_en = 0;
                E_clear = 1;
                // Stop counting sampling timing and clear it
                A_en = 0;
                A_clear = 1;
                // increase char count, and do not clear it
                // enable register
            end

            ERROR : begin
                fe_error = 0;
                if (~timeNextBit)
                  n_state = ERROR;
                else
                  n_state = IDLE;
                // Stop shifting
                S_en = 0;
                // Stop counting loop counter, clear it
                C_en = 0;
                C_clear = 1;
                // keep clearing frame error counter
                E_en = 0;
                E_clear = 1;
                // Stop counting sampling timing and clear it
                A_en = 0;
                A_clear = 1;
                // Stop counting next sampling timing without syncing, clear
                W_en = 1;
                W_clear = 0;
                // do not increase char count, and do not clear it
                Char_en = 0;
                // enable register
                R_en = 0;
            end

        endcase
     end
endmodule : fsm
