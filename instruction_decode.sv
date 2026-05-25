`timescale 1ns/10ps

module instruction_decode(
    output logic [1:0] ALUSrc,
    output logic [1:0] MemtoReg,
    output logic RegWrite,
    output logic MemWrite,
    output logic BrTaken,
    output logic UncondBr,
    output logic [2:0] ALUOp,
    output logic MemRead,
    output logic FlagWrite,
    output logic BrReg,
    output logic [63:0] Da,
    output logic [63:0] Db,
    output logic [63:0] SEAAddr9,
    output logic [63:0] SEAAddr19,
    output logic [63:0] SEAAddr26,
    output logic [63:0] ALUImm,
    output logic [4:0] Aw,
    output logic [4:0] Ab,
    output logic [4:0] Rd,
    output logic [4:0] Rm,
    output logic [4:0] Rn,
    output logic [63:0] selectedBranchPC,
    input logic [63:0] PC,
    input logic [63:0] Dwrite,
    input logic [31:0] Instr,
    input logic clk,
    input logic reset,
    input logic ALUZero,
    input logic Negative,
    input logic Overflow,
    input logic wb_RegWrite,
    input logic [4:0] wb_Aw
    );

    logic [4:0] Aa;

    // control unit
    logic Reg2Loc;

    control gen_cntrl_signal(
        .Instr,
        .ALUZero,
        .Negative,
        .Overflow,
        .Reg2Loc,
        .ALUSrc,
        .MemtoReg,
        .RegWrite,
        .MemWrite,
        .BrTaken,
        .UncondBr,
        .ALUOp,
        .MemRead,
        .FlagWrite,
        .BrReg,
        .Db
    );

    // === Operand Fetch ===
   
    operand_fetch op(
        .Instr,
        .Rd,
        .Rm,
        .Rn,
        .SEAAddr9,
        .SEAAddr19,
        .SEAAddr26,
        .ALUImm
    );

    // registers

     mux2_1_Nbit #(5) read_reg_1(
        .out(Aa),
        .i0(Rn),    
        .i1(Rd),    // BR case, use Rd
        .sel(BrReg)
    );
   
    mux2_1_Nbit #(5) read_reg_2(
        .out(Ab), .i0(Rd), .i1(Rm), .sel(Reg2Loc)
    );  

    mux2_1_Nbit #(5) write_reg(
        .out(Aw), .i0(Rd), .i1(5'd30), .sel(BrTaken)
    ); // should be coming from mem! -> regwrite & brTaken == BL 

   

    regfile register_file(
        .ReadRegister1(Aa),
        .ReadRegister2(Ab),
        .ReadData1(Da),
        .ReadData2(Db),
        .WriteData(Dwrite),
        .WriteRegister(wb_Aw),
        .RegWrite(wb_RegWrite),
        .clk,
        .reset
    );

    // branch stuff
    logic [63:0] branchAddr;
    mux2_1_Nbit #(64) branch_mux(
        .out(branchAddr),
        .i1(SEAAddr26),
        .i0(SEAAddr19),
        .sel(UncondBr)
    );

    logic [63:0] shiftedBranchAddr;
    shifter shifted_addr(
        .value(branchAddr),
        .direction(1'b0),
        .distance(6'd2),
        .result(shiftedBranchAddr)
    );

    logic [63:0] branchPC;
    alu branch(
        .A(PC),
        .B(shiftedBranchAddr),
        .cntrl(3'b010), // add
        .result(branchPC),
        .negative(),
        .zero(),
        .overflow(),
        .carry_out()
    );

    // Select between branchPC and Da (for BR case) to determine next PC

    mux2_1_Nbit #(64) branch_select(
        .out(selectedBranchPC),
        .i1(Da),
        .i0(branchPC),
        .sel(BrReg) // looks like from id stage in slide
    );

    
endmodule