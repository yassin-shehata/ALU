`timescale 1ns/1ps

module alu_tb;

  // DUT signals
  logic [3:0] tb_a, tb_b;
  logic [3:0] tb_op;
  logic [3:0] tb_result;

  // Instantiate DUT
  alu dut (
    .input_a(tb_a),
    .input_b(tb_b),
    .alu_op(tb_op),
    .result(tb_result)
  );

  // Simple reference model
  function automatic logic [3:0] ref_model(
    input logic [3:0] A, B,
    input logic [3:0] OP
  );
    logic [3:0] R;
    logic [1:0] shamt = B[1:0];
    case (OP)
      4'b0000: R = A + B;                      // ADD
      4'b0001: R = A - B;                      // SUB
      4'b0010: R = A & B;                      // AND
      4'b0011: R = A | B;                      // OR
      4'b0100: R = A ^ B;                      // XOR
      4'b0101: R = ~A;                         // NOT
      4'b0110: R = A << shamt;                 // SLL
      4'b0111: R = A >> shamt;                 // SRL
      4'b1000: R = {3'b000, (A == B)};         // EQ
      4'b1001: R = {3'b000, ($signed(A) < $signed(B))}; // SLT
      default: R = 4'b0000;
    endcase
    return R;
  endfunction

  // Checker task
  task automatic check_case(string tag);
    logic [3:0] expected = ref_model(tb_a, tb_b, tb_op);
    if (tb_result !== expected) begin
      $error("[FAIL] %s A=%0h B=%0h op=%0b DUT=%0h EXP=%0h",
             tag, tb_a, tb_b, tb_op, tb_result, expected);
      $fatal;
    end
  endtask

  // Stimulus
  initial begin
    // Directed tests
    tb_a=4'h0; tb_b=4'h0; tb_op=4'b0000; #1; check_case("ADD 0+0");
    tb_a=4'hF; tb_b=4'h1; tb_op=4'b0000; #1; check_case("ADD wrap");
    tb_a=4'h8; tb_b=4'h1; tb_op=4'b0001; #1; check_case("SUB");
    tb_a=4'hA; tb_b=4'h5; tb_op=4'b0010; #1; check_case("AND");
    tb_a=4'hA; tb_b=4'h5; tb_op=4'b0011; #1; check_case("OR");
    tb_a=4'hF; tb_b=4'h0; tb_op=4'b0101; #1; check_case("NOT");
    tb_a=4'h9; tb_b=4'h1; tb_op=4'b0110; #1; check_case("SLL");
    tb_a=4'h9; tb_b=4'h1; tb_op=4'b0111; #1; check_case("SRL");
    tb_a=4'sh8; tb_b=4'sh7; tb_op=4'b1001; #1; check_case("SLT");
    tb_a=4'h5; tb_b=4'h5; tb_op=4'b1000; #1; check_case("EQ");

    // Random test
    for (int i=0; i<20; i++) begin
      tb_a  = $urandom_range(0, 15);
      tb_b  = $urandom_range(0, 15);
      tb_op = $urandom_range(0, 9);
      #1; check_case("RANDOM");
    end

    $display("[PASS] All ALU tests passed.");
    $finish;
  end

endmodule
