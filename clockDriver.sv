module clock_divider
  #(parameter equiv_cycle = 3975)
  (input logic en, clock, reset,
   output logic new_clock);

  logic [$clog2(equiv_cycle)-1:0] Q;
  logic clock_edge, clear;

  // declare control fsm
  clock_fsm control(.*);

  // Counter to count up to equiv cycle
  Counter dut1(.en(en), .clear(clear), .clock(clock), .up(1), .Q(Q));

  // Comparator to check whether we have hit equiv cycle
  Comparator dut2(.A(Q), .B(equiv_cycle), .AeqB(clock_edge));

endmodule : clock_divider

module clock_fsm
  (input logic clock, clock_edge, reset,
    output logic new_clock, clear);

  // here we declare the possible states
  enum logic {out0, out1} state, n_state;

  // flip-flop for next states
  always_ff @(posedge clock) begin
    if(reset)
      state <= out0;
    else
      state <= n_state;
  end

  // next state generation
  always_comb begin
    case(state)
      out0 : begin
        n_state = (clock_edge) ? out1 : out0;
        clear = (clock_edge) ? 1 : 0;
        new_clock = 0;
      end
      out1 : begin
        n_state = (clock_edge) ? out0 : out1;
        clear = (clock_edge) ? 1 : 0;
        new_clock = 1;
      end
    endcase
  end

endmodule : clock_fsm
