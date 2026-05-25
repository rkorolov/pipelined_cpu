module flag_register(
    output logic [3:0] regFlags,
    input logic [3:0] aluFlags,
	input logic FlagWrite,
	input logic clk,
	input logic reset
    );
	
    genvar i;
	generate
		for (i=0; i<4; i ++) begin: eachFlag
		logic mux_out;
			mux2_1 flag_update(.out(mux_out), .i0(regFlags[i]), .i1(aluFlags[i]), .sel(FlagWrite)); // enables flags being updated - otherwise keep previous flag
			
			D_FF_neg d(.q(regFlags[i]), .d(mux_out), .reset, .clk); // we gaf about reset
		end
	endgenerate
endmodule