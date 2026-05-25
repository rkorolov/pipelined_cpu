`timescale 1ns/10ps

module decoder2_4 (out, in, enable);
	output logic [3:0] out;
	
	input logic [1:0] in;
	input logic enable;
	
	logic n_i0, n_i1;
	
	not #(50ps) n0(n_i0, in[0]);
	not #(50ps) n1(n_i1, in[1]);
	
	and #(50ps) a0(out[0], enable, n_i1, n_i0);
	and #(50ps)a1(out[1], enable, n_i1, in[0]);
	and #(50ps)a2(out[2], enable, in[1], n_i0);
	and #(50ps)a3(out[3], enable, in[1], in[0]);
	
endmodule

module decoder3_8(out, in, enable);
	output logic [7:0] out;
	input logic [2:0] in;
	input logic enable;
	
	
	logic e1, e2;
	logic n_i2;
	
	not #(50ps) n0(n_i2, in[2]);
	
	//enable logic from OG enable
	and #(50ps) a0 (e1, enable, n_i2);
	and #(50ps) a1 (e2, enable, in[2]);
	
	decoder2_4 d0 (.out(out[3:0]), .in(in[1:0]), .enable(e1));
	decoder2_4 d1 (.out(out[7:4]), .in(in[1:0]), .enable(e2));
	
endmodule

module decoder5_32 (out, in, enable);
	output logic [31:0] out;
	input logic [4:0] in;
	input logic enable;
	
	logic [3:0] select;
	
	decoder2_4 s0(.out(select), .in(in[4:3]), .enable);
	
	
	decoder3_8 d0(.out(out[7:0]), .in(in[2:0]), .enable(select[0]));
	decoder3_8 d1(.out(out[15:8]), .in(in[2:0]), .enable(select[1]));
	decoder3_8 d2(.out(out[23:16]), .in(in[2:0]), .enable(select[2]));
	decoder3_8 d3(.out(out[31:24]), .in(in[2:0]), .enable(select[3]));
	
endmodule
