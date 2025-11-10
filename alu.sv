// alu.sv
// Parameterized combinational ALU.
// Interface: A, B, op -> Y, carry

`timescale 1ns/1ps

module alu #(
  parameter int W = 8
)(
  input  logic [W-1:0] A,
  input  logic [W-1:0] B,
  input  logic [3:0]   op,
  output logic [W-1:0] Y,
  output logic         carry
);

  // Opcode definitions
  localparam logic [3:0]
    OP_ADD = 4'h0,
    OP_SUB = 4'h1,
    OP_AND = 4'h2,
    OP_OR  = 4'h3,
    OP_XOR = 4'h4,
    OP_XNOR= 4'h5,
    OP_SLL = 4'h6,
    OP_SRL = 4'h7,
    OP_ROL = 4'h8,
    OP_ROR = 4'h9,
    OP_GT  = 4'hA,
    OP_EQ  = 4'hB,
    OP_MUL = 4'hC,
    OP_DIV = 4'hD,
    OP_CLR = 4'hE,
    OP_PASS= 4'hF;

  logic [W-1:0]   result;
  logic           c_flag;
  logic [W:0]     add_ext;
  logic [W:0]     sub_ext;
  logic [2*W-1:0] mul_full;

  always_comb begin
    // defaults
    result   = '0;
    c_flag   = 1'b0;
    add_ext  = '0;
    sub_ext  = '0;
    mul_full = '0;

    unique case (op)

      // A + B
      OP_ADD: begin
        add_ext = {1'b0, A} + {1'b0, B};
        result  = add_ext[W-1:0];
        c_flag  = add_ext[W];
      end

      // A - B
      OP_SUB: begin
        sub_ext = {1'b0, A} - {1'b0, B};
        result  = sub_ext[W-1:0];
        // here c_flag = 1 means no borrow (unsigned)
        c_flag  = sub_ext[W];
      end

      // bitwise AND
      OP_AND: result = A & B;

      // bitwise OR
      OP_OR : result = A | B;

      // bitwise XOR
      OP_XOR: result = A ^ B;

      // bitwise XNOR
      OP_XNOR: result = ~(A ^ B);

      // logical shift left by 1
      OP_SLL: begin
        result = A << 1;
        c_flag = A[W-1];
      end

      // logical shift right by 1
      OP_SRL: begin
        result = A >> 1;
        c_flag = A[0];
      end

      // rotate left by 1
      OP_ROL: begin
        result = {A[W-2:0], A[W-1]};
        c_flag = A[W-1];
      end

      // rotate right by 1
      OP_ROR: begin
        result = {A[0], A[W-1:1]};
        c_flag = A[0];
      end

      // (A > B) ? 1 : 0
      OP_GT: begin
        result = (A > B)
                 ? {{W-1{1'b0}}, 1'b1}
                 : '0;
      end

      // (A == B) ? 1 : 0
      OP_EQ: begin
        result = (A == B)
                 ? {{W-1{1'b0}}, 1'b1}
                 : '0;
      end

      // A * B, take lower W bits, carry if upper bits used
      OP_MUL: begin
        mul_full = A * B;
        result   = mul_full[W-1:0];
        c_flag   = |mul_full[2*W-1:W];
      end

      // A / B, div-by-zero -> 0
      OP_DIV: begin
        if (B != '0)
          result = A / B;
        else
          result = '0;
      end

      // clear
      OP_CLR: result = '0;

      // pass-through A
      OP_PASS: result = A;

      // safe default
      default: result = '0;
    endcase
  end

  assign Y     = result;
  assign carry = c_flag;

endmodule
