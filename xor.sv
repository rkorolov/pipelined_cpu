`timescale 1ns/10ps

// based off of controlled inverter
module xor_gate(out, b, cntrl);
	output logic out;
	input logic  b, cntrl;
	
	logic n_b;
	not #(50ps) n0(n_b, b);
	
	mux2_1 m0(out, b, n_b, cntrl);
	
endmodule
