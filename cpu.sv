`timescale 1ns/10ps

/* 
=== Pipelined 5 Stage CPU Module === 
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

    logic [63:0] if_PC,  id_PC,  ex_PC,  mem_PC;
    logic [31:0] if_Instr, id_Instr, ex_Instr;
    logic [63:0] if_plusFour, id_plusFour, ex_plusFour, mem_plusFour, wb_plusFour;

    // control 
    logic id_RegWrite,  ex_RegWrite,  mem_RegWrite, wb_RegWrite;
    logic id_MemWrite,  ex_MemWrite,  mem_MemWrite;
    logic id_BrTaken,   ex_BrTaken;
    logic id_UncondBr,  ex_UncondBr;
    logic id_MemRead,   ex_MemRead,   mem_MemRead;
    logic id_BrReg,     ex_BrReg;
    logic id_FlagWrite, ex_FlagWrite;
    logic [2:0] id_ALUOp,   ex_ALUOp;
    logic [1:0] id_ALUSrc,  ex_ALUSrc;
    logic [1:0] id_MemtoReg, ex_MemtoReg, mem_MemtoReg, wb_MemtoReg;

    // extended addresses / imm
    logic [63:0] id_SEAAddr9,  ex_SEAAddr9;
    logic [63:0] id_SEAAddr19, ex_SEAAddr19;
    logic [63:0] id_SEAAddr26, ex_SEAAddr26;
    logic [63:0] id_ALUImm,    ex_ALUImm;


    logic [63:0] id_Da, ex_Da;
    logic [63:0] id_Db, ex_Db, mem_Db;
    logic [4:0] id_Aw, ex_Aw, mem_Aw, wb_Aw;
    logic [4:0] id_Ab, ex_Ab;
    logic [4:0] id_Rd, id_Rm, id_Rn;
    logic [4:0] ex_Rm, ex_Rn;
    logic [63:0] id_selectedBranchPC, ex_selectedBranchPC;

    // alu 
    logic ex_ALUZero, ex_Zero, ex_Negative, ex_Overflow, ex_Carry_out;
    logic mem_Negative, mem_Zero, mem_Overflow, mem_Carry_out;
    logic [63:0] ex_ALUResult, mem_ALUResult, wb_ALUResult;

    // memory
    logic [63:0] mem_Dout, wb_Dout;
    logic [63:0] wb_Dwrite;  // data written to regfile in WB

    // forwarding stuff
    logic [1:0] ForwardA, ForwardB;
    logic PCWrite, if_id_write, hazard_Flush;
    logic [63:0] B_inter;

    // Stage 1: === Instruction Fetch === 
    instruction_fetch next_instr(
        .plusFour(if_plusFour),
        .PC(if_PC),
        .PCWrite,
        .Instr(if_Instr),
        .BrTaken(id_BrTaken),            
        .clk,
        .reset,
        .branchPC(id_selectedBranchPC)
    );

    if_id_reg IF_ID(
        .clk,
        .reset,
        .PC_in(if_PC),
        .Instr_in(if_Instr),
        .plusFour_in(if_plusFour),
        .PC_out(id_PC),
        .Instr_out(id_Instr),
        .plusFour_out(id_plusFour),
        .if_id_write,  // freezes during stall
        .Flush(1'b0) // 1 delay slot baseline: no flush after branch
    );

    // Stage 2: === Instruction Decode ===
    instruction_decode id(
        .ALUSrc(id_ALUSrc),
        .MemtoReg(id_MemtoReg),
        .RegWrite(id_RegWrite),
        .MemWrite(id_MemWrite),
        .BrTaken(id_BrTaken),
        .UncondBr(id_UncondBr),
        .ALUOp(id_ALUOp),
        .MemRead(id_MemRead),
        .Da(id_Da),
        .Db(id_Db),
        .SEAAddr9(id_SEAAddr9),
        .SEAAddr19(id_SEAAddr19),
        .SEAAddr26(id_SEAAddr26),
        .selectedBranchPC(id_selectedBranchPC),
        .Dwrite(wb_Dwrite),     // writeback of it all
        .Instr(id_Instr),
        .clk,
        .reset,
        .ALUZero(1'b0), // check if can remove
        .Negative(ex_Negative), // previous flags
        .Overflow(ex_Overflow),
        .FlagWrite(id_FlagWrite),
        .BrReg(id_BrReg),
        .ALUImm(id_ALUImm),
        .Aw(id_Aw),
        .Rd(id_Rd),
        .Rm(id_Rm),
        .Rn(id_Rn),
        .Ab(id_Ab),
        .wb_Aw,
        .wb_RegWrite,
        .PC(id_PC)
    );

    // ID/EX register
    // TODO: remove branch stuff since it's now all done in ID
    id_ex_reg ID_EX(
        .clk,
        .reset,
        .Flush(hazard_Flush), // flushes for load stall
        .plusFour_in(id_plusFour),
        .plusFour_out(ex_plusFour),
        .PC_in(id_PC),
        .PC_out(ex_PC),
        .Instr_in(id_Instr),
        .Instr_out(ex_Instr),
        .Aw_in(id_Aw),
        .Aw_out(ex_Aw),
        .MemtoReg_in(id_MemtoReg),
        .MemtoReg_out(ex_MemtoReg),
        .RegWrite_in(id_RegWrite),
        .RegWrite_out(ex_RegWrite),
        .MemRead_in(id_MemRead),
        .MemRead_out(ex_MemRead),
        .MemWrite_in(id_MemWrite),
        .MemWrite_out(ex_MemWrite),
        .UncondBr_in(id_UncondBr),
        .UncondBr_out(ex_UncondBr),
        .BrTaken_in(id_BrTaken),
        .BrTaken_out(ex_BrTaken),
        .FlagWrite_in(id_FlagWrite),
        .FlagWrite_out(ex_FlagWrite),
        .BrReg_in(id_BrReg),
        .BrReg_out(ex_BrReg),
        .ALUOp_in(id_ALUOp),
        .ALUOp_out(ex_ALUOp),
        .ALUSrc_in(id_ALUSrc),
        .ALUSrc_out(ex_ALUSrc),
        .Da_in(id_Da),
        .Da_out(ex_Da),
        .Db_in(id_Db),
        .Db_out(ex_Db),
        .Ab_in(id_Ab),
        .Ab_out(ex_Ab),
        .SEAAddr9_in(id_SEAAddr9),
        .SEAAddr9_out(ex_SEAAddr9),
        .SEAAddr19_in(id_SEAAddr19),
        .SEAAddr19_out(ex_SEAAddr19),
        .SEAAddr26_in(id_SEAAddr26),
        .SEAAddr26_out(ex_SEAAddr26),
        .ALUImm_in(id_ALUImm),
        .ALUImm_out(ex_ALUImm),
        .Rn_in(id_Rn),
        .Rn_out(ex_Rn),
        .Rm_in(id_Rm),
        .Rm_out(ex_Rm),
        .selectedBranchPC_in(id_selectedBranchPC),
        .selectedBranchPC_out(ex_selectedBranchPC)
    );

    // Stage 3: ==== Execute ===
    execute ex(
        .result(ex_ALUResult),
        .Negative(ex_Negative),
        .Zero(ex_Zero),
        .ALUZero(ex_ALUZero),
        .Overflow(ex_Overflow),
        .Carry_out(ex_Carry_out),
        .B_inter,
        .UncondBr(ex_UncondBr),
        .ALUOp(ex_ALUOp),
        .ALUSrc(ex_ALUSrc),
        .Da(ex_Da),
        .Db(ex_Db),
        .SEAAddr9(ex_SEAAddr9),
        .ALUImm(ex_ALUImm),
        .clk,
        .reset,
        .FlagWrite(ex_FlagWrite),
        .PC(ex_PC),
        .BrReg(ex_BrReg),
        .ForwardA,
        .ForwardB,
        .MemIn(mem_ALUResult),   // prior alu res
        .MemOut(wb_Dwrite)       // memory data -- dbl check lecture slides
    );

    ex_mem_reg EX_MEM(
        .clk,
        .reset,
        .PC_in(ex_PC),
        .PC_out(mem_PC),
        .Aw_in(ex_Aw),
        .Aw_out(mem_Aw),
        .MemtoReg_in(ex_MemtoReg),
        .MemtoReg_out(mem_MemtoReg),
        .RegWrite_in(ex_RegWrite),
        .RegWrite_out(mem_RegWrite),
        .MemRead_in(ex_MemRead),
        .MemRead_out(mem_MemRead),
        .MemWrite_in(ex_MemWrite),
        .MemWrite_out(mem_MemWrite),
        .ALUResult_in(ex_ALUResult),
        .ALUResult_out(mem_ALUResult),
        .Db_in(B_inter), // move forwarded data along pipeline
        .Db_out(mem_Db),
        .plusFour_in(ex_plusFour),
        .plusFour_out(mem_plusFour),
        .Negative_in(ex_Negative),
        .Negative_out(mem_Negative),
        .Zero_in(ex_Zero),
        .Zero_out(mem_Zero),
        .Overflow_in(ex_Overflow),
        .Overflow_out(mem_Overflow),
        .Carryout_in(ex_Carry_out),
        .Carryout_out(mem_Carry_out)
    );

    // Stage 4: === Memory Access ===
    datamem mem(
        .address(mem_ALUResult),
        .write_enable(mem_MemWrite),
        .read_enable(mem_MemRead),
        .write_data(mem_Db),
        .clk,
        .xfer_size(4'd8), // 8 since mem is double word addressable
        .read_data(mem_Dout)
    );

    mem_wb_reg MEM_WB(
        .clk,
        .reset,
        .MemtoReg_in(mem_MemtoReg),
        .MemtoReg_out(wb_MemtoReg),
        .RegWrite_in(mem_RegWrite),
        .RegWrite_out(wb_RegWrite),
        .Aw_in(mem_Aw),
        .Aw_out(wb_Aw),
        .ALUResult_in(mem_ALUResult),
        .ALUResult_out(wb_ALUResult),
        .Dout_in(mem_Dout),
        .Dout_out(wb_Dout),
        .plusFour_in(mem_plusFour),
        .plusFour_out(wb_plusFour)
    );

    // Stage 5: === Write Back ===
    // either write back PC+4 (BL), data from memory, or ALU result, (11 -> don't care case)
    mux4_1_Nbit #(64) wb(
        .out(wb_Dwrite),
        .in({64'b0, wb_plusFour, wb_Dout, wb_ALUResult}),
        .sel(wb_MemtoReg)
    );

    // Forwarding
    forwarding_unit data_forward(
        .ForwardA,
        .ForwardB,
        .id_ex_Rn(ex_Rn),
        .id_ex_Rm(ex_Ab), // either Rm or Rd (STUR cases)
        .ex_mem_Rd(mem_Aw),
        .mem_wb_Rd(wb_Aw),
        .ex_mem_RegWrite(mem_RegWrite),
        .mem_wb_RegWrite(wb_RegWrite)
    );

    // Hazard Detection -> load-use hazard
    // dbl check if needed w delay slots
    hazard_detection load_hazard(
        .PCWrite,
        .Flush(hazard_Flush),
        .if_id_write,
        .id_ex_MemRead(ex_MemRead),
        .id_ex_Rd(ex_Aw),
        .if_id_Rn(id_Rn),
        .if_id_Rm(id_Rm),
        .if_id_Instr(id_Instr),
        .id_ex_RegWrite(ex_RegWrite),
        .ex_mem_RegWrite(mem_RegWrite),
        .ex_mem_Rd(mem_Aw)
    );

endmodule


module cpu_testbench();
    logic clk, reset;

    cpu dut (.clk, .reset);

    parameter CLOCK_PERIOD = 5000;
    initial begin
        clk <= 0;
        forever #(CLOCK_PERIOD/2) clk <= ~clk;
    end

    int i;
    initial begin
        reset = 1; @(posedge clk); // try on negedge
        reset = 0; @(posedge clk);
        for (i = 0; i < 750; i++) begin
            @(posedge clk);
        end
        $stop;
    end

endmodule
