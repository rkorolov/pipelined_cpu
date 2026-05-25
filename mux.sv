`timescale 1ns/10ps

module mux2_1 (out, i0, i1, sel);
	output logic out;
	input logic i0, i1, sel;
	
	logic v0, v1, n_sel;
	
	not #(50ps) n0(n_sel, sel);
	and #(50ps) a0(v0, i1, sel);
	and #(50ps) a1(v1, i0, n_sel);
	
	or #(50ps) o(out, v0, v1);
endmodule

// 00 -> in[0]
// 10 -> in[1]
// 01 -> in[2]
// 11 -> in[3]

module mux4_1(out, in, sel);
	output logic out;
	input logic [3:0] in;
	input logic [1:0] sel;
	
	logic v0, v1;
	
	mux2_1 m0(.out(v0), .i0(in[0]), .i1(in[1]), .sel(sel[0]));
	mux2_1 m1(.out(v1), .i0(in[2]), .i1(in[3]), .sel(sel[0]));
	
	mux2_1 m (.out(out), .i0(v0), .i1(v1), .sel(sel[1]));
endmodule

module mux8_1 (out, in, sel);
	output logic out;
	input logic [7:0] in;
	input logic [2:0] sel;
	logic v0, v1;
	
	mux4_1 m0(.out(v0), .in(in[3:0]), .sel(sel[1:0]));
	mux4_1 m1(.out(v1), .in(in[7:4]), .sel(sel[1:0]));
	
	mux2_1 m2(.out(out), .i0(v0), .i1(v1), .sel(sel[2]));
	
endmodule

module mux16_1 (out, in, sel);
	output logic out;
	input logic [15:0] in;
	input logic [3:0] sel;
	
	logic v0, v1;
	
	mux8_1 m0(.out(v0), .in(in[7:0]), .sel(sel[2:0]));
	mux8_1 m1(.out(v1), .in(in[15:8]), .sel(sel[2:0]));
	
	mux2_1 m2(.out(out), .i0(v0), .i1(v1), .sel(sel[3]));
endmodule

module mux32_1(out, in, sel);
	output logic out;
	input logic [31:0] in;
	input logic [4:0] sel;
	
	logic v0, v1;
	
	mux16_1 m0(.out(v0), .in(in[15:0]), .sel(sel[3:0]));
	mux16_1 m1(.out(v1), .in(in[31:16]), .sel(sel[3:0]));
	
	mux2_1 m2(.out(out), .i0(v0), .i1(v1), .sel(sel[4]));
	
endmodule


module mux2_1_Nbit #(parameter N = 64) (out, i0, i1, sel);
    output logic [N-1:0] out;
    input logic [N-1:0] i0, i1;
    input logic sel;
    
    genvar i;
    generate
        for (i = 0; i < N; i++) begin: mux2bit
            mux2_1 m(.out(out[i]), .i0(i0[i]), .i1(i1[i]), .sel(sel));
        end
    endgenerate
endmodule

module mux4_1_Nbit #(parameter N = 64) (out, in, sel);
    output logic [N-1:0] out;
    input logic [4*N-1:0] in;  // flat: {in3, in2, in1, in0}
    input logic [1:0] sel;

    genvar i;
    generate
        for (i = 0; i < N; i++) begin: mux4bit
            mux4_1 m(
                .out(out[i]),
                .in({in[3*N+i], in[2*N+i], in[N+i], in[i]}),
                .sel(sel)
            );
        end
    endgenerate
endmodule				
