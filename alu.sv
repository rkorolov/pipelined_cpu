`timescale 1ns/10ps

// Meaning of signals in and out of the ALU:

// Flags:
// negative: whether the result output is negative if interpreted as 2's comp.
// zero: whether the result output was a 64-bit zero.
// overflow: on an add or subtract, whether the computation overflowed if the inputs are interpreted as 2's comp.
// carry_out: on an add or subtract, whether the computation produced a carry-out.

// cntrl			Operation						Notes:
// 000:			result = B						value of overflow and carry_out unimportant
// 010:			result = A + B
// 011:			result = A - B
// 100:			result = bitwise A & B		value of overflow and carry_out unimportant
// 101:			result = bitwise A | B		value of overflow and carry_out unimportant
// 110:			result = bitwise A XOR B	value of overflow and carry_out unimportant


module alu(A, B, cntrl, result, negative, zero, overflow, carry_out);
	input logic		[63:0]	A, B;
	input logic		[2:0]		cntrl;
	output logic	[63:0]	result;
	output logic				negative, zero, overflow, carry_out;

	// arithematic section
	logic [63:0] result_ARTH; // results

	multi_bit_adder add_res(
		.out(result_ARTH),
		.carry_out(carry_out),
		.overflow(overflow),
		.cntrl(cntrl[0]),
		.A(A),
		.B(B)
	);

	// logic section
	logic [63:0] result_AND, result_OR, result_XOR;
	
	genvar i;
	generate
		for (i=0; i < 64; i++) begin: eachAluBit
			and #(50ps)  and0(result_AND[i], A[i], B[i]);
			or  #(50ps)  or0(result_OR[i], A[i], B[i]);
			xor_gate     xor0(result_XOR[i], A[i], B[i]);

			// selecting the result
			mux8_1 m0(
				.out(result[i]),
				.in({
					1'b0,          // 111 - don't care
					result_XOR[i], // 110
					result_OR[i],  // 101
					result_AND[i], // 100
					result_ARTH[i], // 011
					result_ARTH[i], // 010
					1'b0,          // 001 - don't care
					B[i]           // 000
				}),
				.sel(cntrl)
			);
		end
	endgenerate
	
	// negative -> true if result[63] is 1, false otherwise
	assign negative = result[63];
	
	// zero -> NOR of all bits in result
	nor64 nor0(zero, result[63:0]);
endmodule
