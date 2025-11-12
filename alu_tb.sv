// alu_tb.sv 
// Self-checking testbench for alu.sv


`timescale 1ns/1ps

module alu_tb;

  localparam int W = 8;

  // Opcode mapping (must match alu.sv)
  localparam logic [3:0]
    OP_ADD  = 4'h0,
    OP_SUB  = 4'h1,
    OP_AND  = 4'h2,
    OP_OR   = 4'h3,
    OP_XOR  = 4'h4,
    OP_XNOR = 4'h5,
    OP_SLL  = 4'h6,
    OP_SRL  = 4'h7,
    OP_ROL  = 4'h8,
    OP_ROR  = 4'h9,
    OP_GT   = 4'hA,
    OP_EQ   = 4'hB,
    OP_MUL  = 4'hC,
    OP_DIV  = 4'hD,
    OP_CLR  = 4'hE,
    OP_PASS = 4'hF;

  // DUT I/O
  logic [W-1:0] A, B;
  logic [3:0]   op;
  logic [W-1:0] Y;
  logic         carry;

  int errors = 0;
  int total  = 0;

  // DUT
  alu #(.W(W)) dut (
    .A(A),
    .B(B),
    .op(op),
    .Y(Y),
    .carry(carry)
  );

  // Expected bundle
  typedef struct packed {
    logic [W-1:0] y;
    logic         c;
  } alu_exp_t;

  // Golden model
  function automatic alu_exp_t golden(
    input logic [W-1:0] a,
    input logic [W-1:0] b,
    input logic [3:0]   op_i
  );
    alu_exp_t       r;
    logic [W:0]     add_ext;
    logic [W:0]     sub_ext;
    logic [2*W-1:0] mul_full;

    r        = '{default:'0};
    add_ext  = '0;
    sub_ext  = '0;
    mul_full = '0;

    unique case (op_i)

      OP_ADD: begin
        add_ext = {1'b0, a} + {1'b0, b};
        r.y     = add_ext[W-1:0];
        r.c     = add_ext[W];
      end

      OP_SUB: begin
        sub_ext = {1'b0, a} - {1'b0, b};
        r.y     = sub_ext[W-1:0];
        r.c     = sub_ext[W];   // 1 = no borrow (unsigned)
      end

      OP_AND : r.y = a & b;
      OP_OR  : r.y = a | b;
      OP_XOR : r.y = a ^ b;
      OP_XNOR: r.y = ~(a ^ b);

      OP_SLL: begin
        r.y = a << 1;
        r.c = a[W-1];
      end

      OP_SRL: begin
        r.y = a >> 1;
        r.c = a[0];
      end

      OP_ROL: begin
        r.y = {a[W-2:0], a[W-1]};
        r.c = a[W-1];
      end

      OP_ROR: begin
        r.y = {a[0], a[W-1:1]};
        r.c = a[0];
      end

      OP_GT: begin
        r.y = (a > b) ? {{W-1{1'b0}}, 1'b1} : '0;
      end

      OP_EQ: begin
        r.y = (a == b) ? {{W-1{1'b0}}, 1'b1} : '0;
      end

      OP_MUL: begin
        mul_full = a * b;
        r.y      = mul_full[W-1:0];
        r.c      = |mul_full[2*W-1:W]; // overflow into upper bits
      end

      OP_DIV: begin
        if (b != '0) r.y = a / b;
        else         r.y = '0;         // div-by-zero handled as 0
      end

      OP_CLR:  r.y = '0;
      OP_PASS: r.y = a;

      default: r.y = '0;
    endcase

    return r;
  endfunction

  // Drive one vector and check
  task automatic drive_and_check(
    input logic [W-1:0] a,
    input logic [W-1:0] b,
    input logic [3:0]   op_i
  );
    alu_exp_t exp;

    A  = a;
    B  = b;
    op = op_i;

    #1; // combinational settle

    exp = golden(a, b, op_i);
    total++;

    assert (Y === exp.y)
      else begin
        $error("Y mismatch op=%0h A=%0h B=%0h  dut=%0h exp=%0h",
               op_i, a, b, Y, exp.y);
        errors++;
      end

    assert (carry === exp.c)
      else begin
        $error("carry mismatch op=%0h A=%0h B=%0h  dut=%0b exp=%0b",
               op_i, a, b, carry, exp.c);
        errors++;
      end
  endtask

  // Exhaustive test
  initial begin
    $display("ALU TB: start");

    for (int o = OP_ADD; o <= OP_PASS; o++) begin
      for (int a = 0; a < (1<<W); a++) begin
        for (int b = 0; b < (1<<W); b++) begin
          drive_and_check(a[W-1:0], b[W-1:0], (o[3:0]));
        end
      end
    end

    $display("Vectors run : %0d", total);

    if (errors == 0) begin
      $display("ALU TB: all checks passed");
    end else begin
      $display("ALU TB: %0d error(s)", errors);
      $fatal;
    end

    $finish;
  end

endmodule
