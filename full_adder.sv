`timescale 1ns/10ps

module full_adder(out, c_out, A, B, c_in);
	output logic out, c_out;
	input logic A, B, c_in;
	
	logic x0out;
	xor_gate x0(x0out, A, B);
	
	xor_gate x1(out, x0out, c_in);
	
	logic a0, a1, a2;
	and #(50ps) (a0, A, B);
	and #(50ps) (a1, B, c_in);
	and #(50ps) (a2, A, c_in);
	
	or #(50ps) (c_out, a0, a1, a2);
	
endmodule
