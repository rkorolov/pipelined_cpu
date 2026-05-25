`timescale 1ns/10ps

module reg64(out, in, enable, clk, reset);
	output logic [63:0] out;
	input logic [63:0] in;
	input logic enable, clk, reset;
	
	logic [63:0] data;
	
	//each register -> 64 DFFs
	genvar i;
	generate
		for (i=0; i< 64; i ++) begin: eachDFF
			mux2_1 m(.out(data[i]), .i0(out[i]), .i1(in[i]), .sel(enable)); // enables data being written - otherwise nothing new
			
			D_FF_neg d(.q(out[i]), .d(data[i]), .reset, .clk); // we gaf about reset
		end
	endgenerate
endmodule
