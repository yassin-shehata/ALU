// alu_tb.sv
`timescale 1ns/1ps

module alu_tb;

  localparam int W = 8;

  logic [W-1:0] A, B;
  logic [3:0]   op;
  logic [W-1:0] Y;
  logic         carry, overflow, zero, negative;

  // DUT
  alu #(.W(W)) dut (
    .A(A), .B(B), .op(op),
    .Y(Y), .carry(carry), .overflow(overflow),
    .zero(zero), .negative(negative)
  );

  // Opcodes (must match DUT)
  localparam logic [3:0]
    OP_ADD = 4'h0, OP_SUB = 4'h1,
    OP_AND = 4'h2, OP_OR  = 4'h3, OP_XOR = 4'h4, OP_XNOR = 4'h5,
    OP_SLL = 4'h6, OP_SRL = 4'h7,
    OP_ROL = 4'h8, OP_ROR = 4'h9,
    OP_GT  = 4'hA, OP_EQ  = 4'hB,
    OP_MUL = 4'hC, OP_DIV = 4'hD,
    OP_CLR = 4'hE, OP_NOP = 4'hF;

  int errors = 0;

  task automatic check(input string name, input logic [W-1:0] exp);
    if (Y !== exp) begin
      $display("[%0t] FAIL %-10s  A=%0h B=%0h op=%0h  exp=%0h got=%0h",
               $time, name, A, B, op, exp, Y);
      errors++;
    end
  endtask

  // Directed tests per op
  task automatic run_directed();
    // ADD
    op=OP_ADD; A=8'h12; B=8'h34; #1; check("ADD", 8'h46);
    op=OP_ADD; A=8'hFF; B=8'h01; #1; check("ADD", 8'h00);

    // SUB
    op=OP_SUB; A=8'h20; B=8'h01; #1; check("SUB", 8'h1F);

    // LOGIC
    op=OP_AND; A=8'hAA; B=8'h0F; #1; check("AND", 8'h0A);
    op=OP_OR ; A=8'hA0; B=8'h0F; #1; check("OR" , 8'hAF);
    op=OP_XOR; A=8'hF0; B=8'h0F; #1; check("XOR", 8'hFF);
    op=OP_XNOR;A=8'hF0; B=8'h0F; #1; check("XNOR",~8'hFF);

    // SHIFTS/ROTATES (one-bit)
    op=OP_SLL; A=8'b1000_0001; B='0; #1; check("SLL", 8'b0000_0010);
    op=OP_SRL; A=8'b1000_0001; B='0; #1; check("SRL", 8'b0100_0000);
    op=OP_ROL; A=8'b1000_0001; B='0; #1; check("ROL", 8'b0000_0011);
    op=OP_ROR; A=8'b1000_0001; B='0; #1; check("ROR", 8'b1100_0000);

    // COMPARES (1/0)
    op=OP_GT;  A=8'd5; B=8'd3; #1; check("GT", 8'h01);
    op=OP_EQ;  A=8'd9; B=8'd9; #1; check("EQ", 8'h01);

    // MUL/DIV (truncated / guarded)
    op=OP_MUL; A=8'd15; B=8'd3; #1; check("MUL", 8'd45);
    op=OP_DIV; A=8'd20; B=8'd4; #1; check("DIV", 8'd5);
    op=OP_DIV; A=8'd7;  B=8'd0; #1; check("DIV0", 8'd0);

    // CLR/NOP
    op=OP_CLR; A=$urandom; B=$urandom; #1; check("CLR", '0);
    op=OP_NOP; A=8'hA5; B=8'h5A; #1; check("NOP", 8'hA5);
  endtask

  // Light randomized sweep for core ops
  task automatic run_random();
    for (int i=0;i<200;i++) begin
      A  = $urandom;
      B  = $urandom;
      op = {2'b0, $urandom}%6; // choose among ADD..XNOR set for easy checking
      #1;
      unique case (op)
        OP_ADD: check("ADD_R", (A+B));
        OP_SUB: check("SUB_R", (A-B));
        OP_AND: check("AND_R", (A&B));
        OP_OR : check("OR_R" , (A|B));
        OP_XOR: check("XOR_R", (A^B));
        OP_XNOR:check("XNOR_R",~(A^B));
        default: ; // skip others in random sweep
      endcase
    end
  endtask

  initial begin
    $display("---- ALU TB START ----");
    run_directed();
    run_random();
    if (errors==0) begin
      $display("ALL TESTS PASS");
    end else begin
      $display("TESTS FAILED: %0d error(s)", errors);
      $fatal;
    end
    $finish;
  end

endmodule