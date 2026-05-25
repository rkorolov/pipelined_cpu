`timescale 1ns/10ps

module multi_bit_adder(out, carry_out, overflow, cntrl, A, B);
	output logic [63:0] out;
	output logic        carry_out, overflow;
	input logic         cntrl; // ~ADD / SUB from cntrl signal
	input logic [63:0]  A, B;
	
	logic [64:0] carry;
	assign carry[0] = cntrl;

	logic [63:0] b_wire;
	
	genvar i;
	generate
		for (i=0; i<64; i++) begin: eachBit
			xor_gate x0(b_wire[i], B[i], cntrl); 
		
			full_adder fa(
				.out(out[i]), 
				.c_out(carry[i+1]), 
				.A(A[i]),
				.B(b_wire[i]), 
				.c_in(carry[i])
			);
			
		end
	endgenerate

	// carry out
	or #(50ps) c0(carry_out, carry[64], 1'b0);

	//overflow
	xor_gate x1(overflow, carry[63], carry[64]);
endmodule
