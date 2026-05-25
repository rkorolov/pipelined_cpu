module D_FF #(parameter WIDTH=1) (q, d, reset, clk);
	output reg [WIDTH-1:0] q;
	input [WIDTH-1:0] d;
	input reset, clk;
	
	always_ff @(posedge clk)
	if (reset)
		q <= 0; // On reset, set to 0
	else
		q <= d; // Otherwise out = d
endmodule

module D_FF_neg #(parameter WIDTH=1) (q, d, reset, clk);
	output reg [WIDTH-1:0] q;
	input [WIDTH-1:0] d;
	input reset, clk;
	
	always_ff @(negedge clk)
	if (reset)
		q <= 0; // On reset, set to 0
	else
		q <= d; // Otherwise out = d
endmodule
