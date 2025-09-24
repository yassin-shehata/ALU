// Basys3 wrapper for 4-bit ALU
module top_basys3_4bit (
  input  logic [15:0] sw,  // Basys3 switches
  output logic [15:0] led // Basys3 LEDs
);

  // Map switches to ALU inputs
  logic [3:0] a   = sw[3:0] // A = SW0-SW3
  logic [3:0] b   = sw[7:4];  // B = SW4-SW7
  logic [3:0] op  = sw[11:8]; // opcode = SW8-SW11
  logic [3:0] y;  // ALU result


  // Instantiate your ALU 
  alu dut (
    .input_a(a),
    .input_b(b),
    .alu_op(op),
    .result(y)
  );

 
  assign led[15:12] = y;     // result
  assign led[11:8]  = op;   // show opcode
  assign led[7:4]   = b;     // show B
  assign led[3:0]   = a;     // show A

endmodule
