// alu.sv - 8-bit ALU
`timescale 1ns/1ps

module alu (
  input  logic [7:0] input_a,      // first operand (8-bit)
  input  logic [7:0] input_b,      // second operand (8-bit)
  input  logic [3:0] alu_op,       // 4-bit operation code
  output logic [7:0] result        // ALU result (8-bit)
);

  // binary operation codes
  localparam logic [3:0]
    OP_ADD = 4'b0000,  // A + B
    OP_SUB = 4'b0001,  // A - B
    OP_AND = 4'b0010,  // A & B
    OP_OR  = 4'b0011,  // A | B
    OP_XOR = 4'b0100,  // A ^ B
    OP_NOT = 4'b0101,  // ~A
    OP_SLL = 4'b0110,  // A << shamt
    OP_SRL = 4'b0111,  // A >> shamt
    OP_EQ  = 4'b1000,  // (A == B) ? 1 : 0 (in LSB)
    OP_SLT = 4'b1001;  // signed(A) < signed(B) ? 1 : 0 (in LSB)

  // shift amount = low 3 bits of B (because 8-bit ALU: 0..7)
  logic [2:0] shift_amount;

  always_comb begin
    shift_amount = input_b[2:0];
    unique case (alu_op)
      OP_ADD: result = input_a + input_b;
      OP_SUB: result = input_a - input_b;
      OP_AND: result = input_a & input_b;
      OP_OR : result = input_a | input_b;
      OP_XOR: result = input_a ^ input_b;
      OP_NOT: result = ~input_a;
      OP_SLL: result = input_a << shift_amount;
      OP_SRL: result = input_a >> shift_amount;
      OP_EQ : result = {7'b0, (input_a == input_b)};
      OP_SLT: result = {7'b0, ($signed(input_a) < $signed(input_b))};
      default: result = 8'b0;
    endcase
  end

endmodule
