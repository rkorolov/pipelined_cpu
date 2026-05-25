`timescale 1ns/10ps

/* 
=== Single-Cycle 5 Stage CPU Module === 
    * Instruction Fetch: Obtain instruction from program storage
    * Instruction Decode: Determine required actions and instruction size (control + registers + sign extend)
    * Execute: Compute result value or status (ALUs)
    * Memory Access: Deposit results in storage for later use (memory - and also reg file)
    * Write Back: Write data back into register file
*/

module cpu(
    input logic clk,
    input logic reset
    );

    logic [63:0] PC;
    logic [31:0] Instr;
    logic [63:0] plusFour;

    logic Reg2Loc, RegWrite, MemWrite, BrTaken, UncondBr, MemRead, BrReg, FlagWrite;
    logic [2:0] ALUOp;
    logic [1:0] ALUSrc, MemtoReg;
    logic [63:0] Da, Db, SEAAddr9, SEAAddr19, SEAAddr26, ALUImm;

    logic ALUZero, Zero, Negative, Overflow, Carry_out;
    logic [63:0] ALUResult, selectedBranchPC;

    logic [63:0] Dout;
    logic [63:0] Dwrite;

    // Stage 1: === Instruction Fetch === 
    instruction_fetch next_instr(
        .plusFour,
        .PC,
        .Instr,
        .BrTaken,
        .clk,
        .reset,
        .branchPC(selectedBranchPC)
    );

    // Stage 2: === Instruction Decode ===
    instruction_decode id(
        .Reg2Loc,
        .ALUSrc,
        .MemtoReg,
        .RegWrite,
        .MemWrite,
        .BrTaken,
        .UncondBr,
        .ALUOp,
        .MemRead,
        .Da,
        .Db,
        .SEAAddr9,
        .SEAAddr19,
        .SEAAddr26,
        .Dwrite,
        .Instr,
        .clk,
        .reset,
        .ALUZero,
        .Negative,
        .Overflow,
        .FlagWrite,
        .BrReg,
        .ALUImm
    );


    // Stage 3: ==== Execute ===
    execute datapath(
        .result(ALUResult),
        .Negative, 
        .Zero,
        .ALUZero,
        .Overflow,
        .Carry_out,
        .selectedBranchPC,
        .Reg2Loc,
        .UncondBr,
        .ALUOp,
        .ALUSrc,
        .Da,
        .Db,
        .SEAAddr9,
        .SEAAddr19,
        .SEAAddr26,
        .ALUImm,
        .clk,
        .reset,
        .FlagWrite,
        .PC,
        .BrReg
    );

    // Stage 4: === Memory Access ===
    datamem dmem (
        .address(ALUResult),
        .write_enable(MemWrite),
        .read_enable(MemRead),
        .write_data(Db),
        .clk(clk),
        .xfer_size(4'b1000),
        .read_data(Dout)
    );

    // Stage 5: === Write Back ===
    // Choose either data memory, ALU result, or PC+4 (BL case) to write back to register file
    mux4_1_Nbit #(64) mem_to_reg( 
        .out(Dwrite),
        .in({64'b0, plusFour, Dout, ALUResult}),
        .sel(MemtoReg)
    ); 

endmodule

module cpu_testbench();
    logic clk, reset;

    cpu dut (.clk, .reset);

    parameter CLOCK_PERIOD = 60000;
	initial begin
		clk <= 0;
		forever #(CLOCK_PERIOD/2) clk <= ~clk;
	end

    int i;
	initial begin
		reset = 1; @(posedge clk); @(posedge clk); // zero out PC
		reset = 0; @(posedge clk);
		for (i = 0; i < 500; i++) begin
			@(posedge clk);
		end
		$stop;
	end

endmodule