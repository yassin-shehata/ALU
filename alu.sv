// alu.sv
// Parameterized ALU with status flags
module alu #(
  parameter int W = 8
)(
  input  logic [W-1:0] A,
  input  logic [W-1:0] B,
  input  logic [3:0]   op,           // operation select
  output logic [W-1:0] Y,            // result
  output logic         carry,        // carry out (add/sub)
  output logic         overflow,     // signed overflow (add/sub)
  output logic         zero,         // Y == 0
  output logic         negative      // MSB of Y
);

  // Opcodes
  localparam logic [3:0]
    OP_ADD = 4'h0, OP_SUB = 4'h1,
    OP_AND = 4'h2, OP_OR  = 4'h3, OP_XOR = 4'h4, OP_XNOR = 4'h5,
    OP_SLL = 4'h6, OP_SRL = 4'h7,
    OP_ROL = 4'h8, OP_ROR = 4'h9,
    OP_GT  = 4'hA, OP_EQ  = 4'hB,
    OP_MUL = 4'hC, OP_DIV = 4'hD,
    OP_CLR = 4'hE, OP_NOP = 4'hF;

  logic [W:0]   add_ext, sub_ext;   // one extra bit for carry/borrow
  logic [W-1:0] result;

  always_comb begin
    // defaults
    result   = '0;
    carry    = 1'b0;
    overflow = 1'b0;

    // precompute for flags
    add_ext = {1'b0, A} + {1'b0, B};
    sub_ext = {1'b0, A} - {1'b0, B};

    unique case (op)
      OP_ADD: begin
        result   = add_ext[W-1:0];
        carry    = add_ext[W]; // unsigned carry
        // 2's complement overflow detection
        overflow = (~(A[W-1] ^ B[W-1])) & (A[W-1] ^ result[W-1]);
      end
      OP_SUB: begin
        result   = sub_ext[W-1:0];
        carry    = ~sub_ext[W]; // carry=1 means no borrow (6502 style); adjust if you prefer
        overflow = ((A[W-1] ^ B[W-1])) & (A[W-1] ^ result[W-1]);
      end

      OP_AND:   result = A & B;
      OP_OR :   result = A | B;
      OP_XOR:   result = A ^ B;
      OP_XNOR:  result = ~(A ^ B);

      OP_SLL:   result = A << 1;
      OP_SRL:   result = A >> 1;

      OP_ROL:   result = {A[W-2:0], A[W-1]};
      OP_ROR:   result = {A[0], A[W-1:1]};

      OP_GT :   result = (A > B) ? {{W-1{1'b0}}, 1'b1} : '0;
      OP_EQ :   result = (A == B)? {{W-1{1'b0}}, 1'b1} : '0;

      OP_MUL:   result = A * B;                // truncated to W bits
      OP_DIV:   result = (B != '0) ? (A / B) : '0; // guard div-by-zero

      OP_CLR:   result = '0;
      default:  result = A; // NOP: pass-through
    endcase
  end

  // common flags
  assign Y        = result;
  assign zero     = (result == '0);
  assign negative = result[W-1];

endmodule
