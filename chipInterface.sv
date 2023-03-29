`default_nettype none
module chipInterface(
    input logic CLOCK_50,
    input logic reset, UART_RXD,
    input logic[3:0] KEY,
    output logic [6:0] HEX7, HEX6
);
    // here we declare the output
    logic [511:0] m; // this should be connected to out
    logic [8:0] curr_add; // this will be our connection to out
    // here we declare counter vars
    logic c_clr, c_en, isNew;
    logic click;
    // Assigning the FPGA inputs
    assign reset = ~KEY[2];
    assign click = ~KEY[3];

    // here we declare our receiver
    task2 R (.clock(CLOCK_50),
              .reset(reset),
              .serialIn(UART_RXD),
              .messageBytes(m),
              .isNew(isNew));

    // fsm to deal with shift reg
    interface_fsm control(.*);

    // here we declare the counter
    Counter_8 dut1(.en(c_en), .clear(c_clr), .clock(CLOCK_50), .up(1), .Q(curr_add));

endmodule : chipInterface

module interface_fsm(
    input logic CLOCK_50, reset, click,
    input logic [8:0] curr_add,
    input logic [511:0] m,
    output logic c_en, c_clr,
    output logic [6:0] HEX6, HEX7
);
    // assign seven seg_values
    logic [6:0] s0, s1, s2, s3, s4, s5, s6, s7, s8, s9;
    
    // here we are declaring 3 states
    enum logic [1:0] {start, view, next_8} state, n_state;

    // here we are assigning the 7 segment display
    always_comb begin 
        s0 = ~7'b0111111;
        s1 = ~7'b0000110;
        s2 = ~7'b1011011;
        s3 = ~7'b1001111;
        s4 = ~7'b1100110;
        s5 = ~7'b1101101;
        s6 = ~7'b1111101;
        s7 = ~7'b0000111;
        s8 = ~7'b1111111;
        s9 = ~7'b1100111;
    end
    
    // here we are defining reset and state transitions
    always_ff @(posedge CLOCK_50) begin 
        if(reset)
            state = start;
        else
            state = n_state;
    end

    // here we come to the state generation
    always_comb begin
    case(state) 
        // here in the start state we wait for click
        start : begin 
            if (click)
                n_state = view;
            else
                n_state = start;
            c_en = 0;
            c_clr = 0;
        end
        // here we will be in the state to output mem[addr]
        view : begin 
            if (click)
                n_state = next_8;
            else
                n_state = view;
            c_en = 0;
            c_clr = 0;
        end
        // here we will increment our address by 8
        next_8 : begin
            n_state = view; 
            c_en = 1;
            c_clr = 0;
        end
        default : begin 
            n_state = start;
            c_en = 0;
            c_clr = 1;
        end 
    endcase
    end
    // here we come up with output generation
    always_comb begin
    unique case(state) 
        start : begin 
            HEX6 = 7'b1111111;
            HEX7 = 7'b1111111;
        end
        view: begin 
            case(m[curr_add+8:curr_add])
                8'd97, 8'd65 : begin 
                    HEX7 = s6;
                    HEX6 = s5;
                end
                8'd98, 8'd66 : begin 
                    HEX7 = s6;
                    HEX6 = s6; 
                end
                8'd99, 8'd67 : begin 
                    HEX7 = s6;
                    HEX6 = s7;
                end
                8'd100, 8'd68 : begin 
                    HEX7 = s6;
                    HEX6 = s8;
                end
                8'd101, 8'd69 : begin 
                    HEX7 = s6;
                    HEX6 = s9;
                end
                8'd102, 8'd70 : begin 
                    HEX7 = s7;
                    HEX6 = s0;
                end
                8'd103, 8'd71 : begin 
                    HEX7 = s7;
                    HEX6 = s1;
                end
                8'd104, 8'd72 : begin 
                    HEX7 = s7;
                    HEX6 = s2;
                end
                8'd105, 8'd73 : begin 
                    HEX7 = s7;
                    HEX6 = s3;
                end
                8'd106, 8'd74 : begin 
                    HEX7 = s7;
                    HEX6 = s4;
                end
                8'd107, 8'd75 : begin 
                    HEX7 = s7;
                    HEX6 = s5;
                end
                8'd108, 8'd76 : begin 
                    HEX7 = s7;
                    HEX6 = s6;
                end
                8'd109, 8'd77 : begin 
                    HEX7 = s7;
                    HEX6 = s7;
                end
                8'd110, 8'd78 : begin 
                    HEX7 = s7;
                    HEX6 = s8;
                end
                8'd111, 8'd79 : begin 
                    HEX7 = s7;
                    HEX6 = s9;
                end
                8'd112, 8'd80 : begin 
                    HEX7 = s8;
                    HEX6 = s0;
                end
                8'd113, 8'd81 : begin 
                    HEX7 = s8;
                    HEX6 = s1;
                end
                8'd114, 8'd82 : begin 
                    HEX7 = s8;
                    HEX6 = s2;
                end
                8'd115, 8'd83 : begin 
                    HEX7 = s8;
                    HEX6 = s3;
                end
                8'd116, 8'd84 : begin 
                    HEX7 = s8;
                    HEX6 = s4;
                end
                8'd117, 8'd85 : begin 
                    HEX7 = s8;
                    HEX6 = s5;
                end
                8'd118, 8'd86 : begin 
                    HEX7 = s8;
                    HEX6 = s6;
                end
                8'd119, 8'd87 : begin 
                    HEX7 = s8;
                    HEX6 = s7;
                end
                8'd120, 8'd88 : begin 
                    HEX7 = s8;
                    HEX6 = s8;
                end
                8'd121, 8'd89 : begin 
                    HEX7 = s8;
                    HEX6 = s9;
                end
                8'd122, 8'd90 : begin 
                    HEX7 = s9;
                    HEX6 = s0;
                end
                default : {HEX7, HEX6} = {s2, s1}; 
            endcase
        end
        next_8: begin 
            HEX6 = 7'b1111111;
            HEX7 = 7'b1111111;
        end
    endcase
    end
endmodule : interface_fsm

module Counter_8
  #(parameter WIDTH=9)
  (input  logic [WIDTH-1:0] D,
   input  logic             en, clear, load, clock, up,
   output logic [WIDTH-1:0] Q);

  always_ff @(posedge clock)
    if (clear)
      Q <= {WIDTH {1'b0}};
    else if (load)
      Q <= D;
    else if (en)
      if (up)
        Q <= Q + 3'd8;
      else
        Q <= Q - 3'd8;

endmodule : Counter_8
