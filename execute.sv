`timescale 1ns/10ps

module execute(
    output logic [63:0] result,
    output logic Negative,
    output logic ALUZero,
    output logic Zero,
    output logic Overflow,
    output logic Carry_out,
    output logic [63:0] B_inter,
    input logic UncondBr, // remove!
    input logic [2:0] ALUOp,
    input logic [1:0] ALUSrc,
    input logic [63:0] Da,
    input logic [63:0] Db,
    input logic [63:0] SEAAddr9,
    input logic [63:0] ALUImm,
    input logic clk,
    input logic reset,
    input logic FlagWrite,
    input logic [63:0] PC,
    input logic BrReg,
    input logic [1:0] ForwardA,
    input logic [1:0] ForwardB,
    input logic [63:0] MemIn,
    input logic [63:0] MemOut
    );
    
    
    logic [63:0] A, B;

    // choose first ALU operand
    // 11 -> X, 10 -> prior ALU res, 01 -> from memory / earlier res, 00 -> no forwarding
    mux4_1_Nbit #(64) forward_A(
        .sel(ForwardA),
        .in({64'b0, MemIn, MemOut, Da}),
        .out(A)
    );

    // choose B intermediate(?) -> check for data hazards then proceed
    mux4_1_Nbit #(64) forward_B(
        .sel(ForwardB),
        .in({64'b0, MemIn, MemOut, Db}),
        .out(B_inter)
    );
    
    // chose second ALU operand (either SEAAddr9, ALUImm, or Db)
    mux4_1_Nbit #(64) alu_source(
        .out(B), 
        .in({64'b0, SEAAddr9, ALUImm, B_inter}), 
        .sel(ALUSrc)
    );

    // flags
    logic negative, zero, overflow, carry_out;
    alu a(
        .A,
        .B,
        .cntrl(ALUOp),
        .result,
        .negative,
        .zero,
        .overflow,
        .carry_out
    );
    assign ALUZero = zero;

    
    // generate register flags

    flag_register flags(
        .regFlags({Negative, Zero, Overflow, Carry_out}),
        .aluFlags({
            negative,
            zero,
            overflow,
            carry_out
        }),
        .FlagWrite,
        .clk,
        .reset
    );

endmodule