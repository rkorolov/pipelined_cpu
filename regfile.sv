`timescale 1ns/10ps

module regfile (ReadData1, ReadData2, WriteData, 
					 ReadRegister1, ReadRegister2, WriteRegister,
					 RegWrite, clk, reset);
	/*
		Notes:
			- clock delay?
			- enable protection for enable
	*/
	
	output logic [63:0] ReadData1, ReadData2;
	
	input logic [63:0] WriteData;
	input logic [4:0] WriteRegister, ReadRegister1, ReadRegister2;
	input logic RegWrite, clk, reset;
	
	logic [31:0] regEnable;
	logic [31:0][63:0] data; // each data[index] (aka register), has 64 bits
	
	
	// 5:32 decoder -> selects which register gets register write
	decoder5_32 d0(.out(regEnable), .in(WriteRegister), .enable(RegWrite));

	
	//for each register (0 -> 31), make 64 DFFs
	genvar i;
	generate
		for (i=0; i < 31; i++) begin: eachRegister
			reg64 r(.out(data[i]), .in(WriteData), .enable(regEnable[i]), .clk, .reset);
		end

		reg64 rzr(.out(data[31]), .in(64'b0), .enable(regEnable[31]), .clk, .reset);
	endgenerate
	

	genvar k, l;
	generate
		for (k=0; k < 64; k++) begin: eachMux // better name is each dataIn for mux or eachReg
		
			logic [31:0] dataOut;
			for (l=0; l < 31; l++) begin: eachOut
				assign dataOut[l] = data[l][k];
			end
			
			//overwrite R31 -> RZR
			assign dataOut[31] = 1'b0;
		
			mux32_1 m1(.out(ReadData1[k]), .in(dataOut), .sel(ReadRegister1));
			mux32_1 m2(.out(ReadData2[k]), .in(dataOut), .sel(ReadRegister2));
		end
	endgenerate
endmodule
