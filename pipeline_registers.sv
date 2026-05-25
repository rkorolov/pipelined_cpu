`timescale 1ns/10ps

/* 
    IF/ID register keeps track of info from instr fetch -> instr decode
    * PC
    * Instr

    Note: in general, akwasys write on pipelined registers
*/
module if_id_reg(
    input logic clk,
    input logic reset,
    input logic [63:0] PC_in,
    input logic [31:0] Instr_in,
    output logic [63:0] PC_out,
    output logic [31:0] Instr_out,
    input logic [63:0] plusFour_in,
    output logic [63:0] plusFour_out,
    input logic if_id_write,  // either write or hold values 
    input logic Flush         // clear everything out
    );

    logic [63:0] PC_wire, plusFour_wire;
    logic [31:0] Instr_wire;

    logic reset_wire;
    or #(50ps) flush_reset(reset_wire, Flush, reset);

    // Enables
    mux2_1_Nbit #(32) instruction_enable(
        .sel(if_id_write),
        .i0(Instr_out),
        .i1(Instr_in),
        .out(Instr_wire)
    );

    mux2_1_Nbit #(64) pc_enable(
        .sel(if_id_write),
        .i0(PC_out),
        .i1(PC_in),
        .out(PC_wire)
    );

    mux2_1_Nbit #(64) plusFour_enable(
        .sel(if_id_write),
        .i0(plusFour_out),
        .i1(plusFour_in),
        .out(plusFour_wire)
    );

    // PC
    D_FF #(64) program_counter(
        .q(PC_out),
        .d(PC_wire),
        .clk,
        .reset(reset_wire)
    );

    // Instruction
    D_FF #(32) instruction_update(
        .q(Instr_out),
        .d(Instr_wire),
        .clk,
        .reset(reset_wire)
    );

    // PC+4
    D_FF #(64) plus_four_counter(
        .q(plusFour_out),
        .d(plusFour_wire),
        .clk,
        .reset(reset_wire)
    );
endmodule

/* 
    ID/EX register keeps track of info from instr decode -> execute
    * PC
    * Instr
    * Read data 1 (Da)
    * Read data 2 (Db)
    * All sign extended stuff (including immeadiate)
    * Rd

    Control:
    - all except reg2loc

    Note: in general, akwasys write on pipelined registers
*/
module id_ex_reg(
    output logic [63:0] PC_out,
    output logic [31:0] Instr_out,
    output logic [4:0] Aw_out,
    output logic [1:0] MemtoReg_out,
    output logic RegWrite_out,
    output logic MemRead_out,
    output logic MemWrite_out,
    output logic UncondBr_out,
    output logic BrTaken_out,
    output logic FlagWrite_out,
    output logic BrReg_out,
    output logic [2:0] ALUOp_out,
    output logic [1:0] ALUSrc_out,
    output logic [63:0] Da_out,
    output logic [63:0] Db_out,
    output logic [63:0] SEAAddr9_out,
    output logic [63:0] SEAAddr19_out,
    output logic [63:0] SEAAddr26_out,
    output logic [63:0] ALUImm_out,
    input logic clk,
    input logic reset,
    input logic Flush,
    input logic [63:0] PC_in,
    input logic [31:0] Instr_in,
    input logic [4:0] Aw_in,
    input logic [1:0] MemtoReg_in,
    input logic RegWrite_in,
    input logic MemRead_in,
    input logic MemWrite_in,
    input logic [2:0] ALUOp_in,
    input logic [1:0] ALUSrc_in,
    input logic UncondBr_in,
    input logic BrTaken_in,
    input logic FlagWrite_in,
    input logic BrReg_in,
    input logic [63:0] Da_in,
    input logic [63:0] Db_in,
    input logic [63:0] SEAAddr9_in,
    input logic [63:0] SEAAddr19_in,
    input logic [63:0] SEAAddr26_in,
    input logic [63:0] ALUImm_in,
    input logic [63:0] plusFour_in,
    output logic [63:0] plusFour_out,
    input logic [4:0] Rn_in,
    input logic [4:0] Rm_in,
    output logic [4:0] Rn_out,
    output logic [4:0] Rm_out,
    output logic [4:0] Ab_out,
    input logic [4:0] Ab_in,
    input logic [63:0] selectedBranchPC_in,
    output logic [63:0] selectedBranchPC_out
    );

    // Combined reset: flush (branch taken) or global reset clears this stage to NOP
    logic reset_wire;
    or #(50ps) flush_reset(reset_wire, Flush, reset);

    //selectedBranchPC
    D_FF #(64) sel_bPC(
        .q(selectedBranchPC_out),
        .d(selectedBranchPC_in),
        .clk,
        .reset(reset_wire)
    );

    // Rn
    D_FF #(5) first_reg_op(
        .q(Rn_out),
        .d(Rn_in),
        .clk,
        .reset(reset_wire)
    );

    // Rm
    D_FF #(5) second_reg_op(
        .q(Rm_out),
        .d(Rm_in),
        .clk,
        .reset(reset_wire)
    );

    // PC
    D_FF #(64) program_counter(
        .q(PC_out),
        .d(PC_in),
        .clk,
        .reset(reset_wire)
    );

    // PC+4
    D_FF #(64) plus_four_counter(
        .q(plusFour_out),
        .d(plusFour_in),
        .clk,
        .reset(reset_wire)
    );

    // Instruction
    D_FF #(32) instruction_update(
        .q(Instr_out),
        .d(Instr_in),
        .clk,
        .reset(reset_wire)
    );

    // Write address (Aw) -> for BL purposes
    D_FF #(5) write_address_update(
        .q(Aw_out),
        .d(Aw_in),
        .clk,
        .reset(reset_wire)
    );

    D_FF #(5) second_read_reg(
        .q(Ab_out),
        .d(Ab_in),
        .clk,
        .reset(reset_wire)
    );

    // === Register File Stuff ===

    D_FF #(64) rd1(
        .q(Da_out),
        .d(Da_in),
        .clk,
        .reset(reset_wire)
    );

    D_FF #(64) rd2(
        .q(Db_out),
        .d(Db_in),
        .clk,
        .reset(reset_wire)
    );

    // Sign Extended Stuff
    D_FF #(64) se9(
        .q(SEAAddr9_out),
        .d(SEAAddr9_in),
        .clk,
        .reset(reset_wire)
    );

    D_FF #(64) se19(
        .q(SEAAddr19_out),
        .d(SEAAddr19_in),
        .clk,
        .reset(reset_wire)
    );

    D_FF #(64) se26(
        .q(SEAAddr26_out),
        .d(SEAAddr26_in),
        .clk,
        .reset(reset_wire)
    );

    D_FF #(64) imm(
        .q(ALUImm_out),
        .d(ALUImm_in),
        .clk,
        .reset(reset_wire)
    );

    // writeback control
    writeback_control_reg id_ex_w(
        .MemtoReg_out,
        .MemtoReg_in,
        .RegWrite_out,
        .RegWrite_in,
        .clk,
        .reset(reset_wire)
    );

    // memory control
    memory_control_reg id_ex_m(
        .MemRead_out,
        .MemWrite_out,
        .clk,
        .reset(reset_wire),
        .MemRead_in,
        .MemWrite_in
    );

    // execute control
    execute_control_reg id_ex_e(
        .UncondBr_out,
        .BrTaken_out,
        .ALUOp_out,
        .ALUSrc_out,
        .FlagWrite_out,
        .BrReg_out,
        .clk,
        .reset(reset_wire),
        .ALUOp_in,
        .ALUSrc_in,
        .UncondBr_in,
        .BrTaken_in,
        .FlagWrite_in,
        .BrReg_in
    );
endmodule

/* 
    EX/MEM register keeps track of info from execute to memory access stage
    * ALU results (regular ALU op + branch adding)
    * Read data 2 (Db)
    * Rd
    * flags

    Control:
    - writeback + memory

    Note: in general, akwasys write on pipelined registers
*/
module ex_mem_reg(
    input logic clk,
    input logic reset,
    input logic [63:0] PC_in,
    output logic [63:0] PC_out,
    input logic [4:0] Aw_in,
    output logic [4:0] Aw_out,
    output logic [1:0] MemtoReg_out,
    input logic [1:0] MemtoReg_in,
    output logic RegWrite_out,
    input logic RegWrite_in,
    output logic MemRead_out,
    output logic MemWrite_out,
    input logic MemRead_in,
    input logic MemWrite_in,
    input logic [63:0] ALUResult_in,
    output logic [63:0] ALUResult_out,
    input logic [63:0] Db_in,
    output logic [63:0] Db_out,
    input logic [63:0] plusFour_in,
    output logic [63:0] plusFour_out,
    // condition flags (forwarded to ID for conditional branches)
    input logic  Negative_in,
    output logic Negative_out,
    input logic  Zero_in,
    output logic Zero_out,
    input logic  Overflow_in,
    output logic Overflow_out,
    input logic  Carryout_in,
    output logic Carryout_out
    );

    // PC
    D_FF #(64) program_counter(
        .q(PC_out),
        .d(PC_in),
        .clk,
        .reset
    );

    // PC+4
    D_FF #(64) plus_four_counter(
        .q(plusFour_out),
        .d(plusFour_in),
        .clk,
        .reset
    );

    // Aw (destination register)
    D_FF #(5) rd_update(
        .q(Aw_out),
        .d(Aw_in),
        .clk,
        .reset
    );

    // Read data 2 -> Db (store data)
    D_FF #(64) rd2(
        .q(Db_out),
        .d(Db_in),
        .clk,
        .reset
    );

    // ALU result
    D_FF #(64) alu_res(
        .q(ALUResult_out),
        .d(ALUResult_in),
        .clk,
        .reset
    );

    // flags
    D_FF #(1) neg_flag(.q(Negative_out), .d(Negative_in), .clk, .reset);
    D_FF #(1) zero_flag(.q(Zero_out), .d(Zero_in), .clk, .reset);
    D_FF #(1) overflow_flag(.q(Overflow_out), .d(Overflow_in), .clk, .reset);
    D_FF #(1) cout_flag( .q(Carryout_out), .d(Carryout_in), .clk, .reset);

    // writeback control
    writeback_control_reg ex_mem_w(
        .MemtoReg_out,
        .MemtoReg_in,
        .RegWrite_out,
        .RegWrite_in,
        .clk,
        .reset
    );

    // memory control
    memory_control_reg ex_mem_m(
        .MemRead_out,
        .MemWrite_out,
        .clk,
        .reset,
        .MemRead_in,
        .MemWrite_in
    );
endmodule

/* 
    MEM/WB register keeps track of info from memory -> writeback
    * Read data -> Dout
    * ALU result -> address
    * Rd

    Control:
    - all signals execept for Reg2Loc

    Note: in general, akwasys write on pipelined registers
*/
module mem_wb_reg(
    input logic clk,
    input logic reset,
    output logic [1:0] MemtoReg_out,
    input logic [1:0] MemtoReg_in,
    output logic RegWrite_out,
    input logic RegWrite_in,
    input logic [4:0] Aw_in,
    output logic [4:0] Aw_out,
    input logic [63:0] ALUResult_in,
    output logic [63:0] ALUResult_out,
    input logic [63:0] Dout_in,
    output logic [63:0] Dout_out,
    input logic [63:0] plusFour_in,
    output logic [63:0] plusFour_out
    );

    // PC+4
    D_FF #(64) plus_four_counter(
        .q(plusFour_out),
        .d(plusFour_in),
        .clk,
        .reset
    );

    // Rd -> for BL purposes
    D_FF #(5) rd_update(
        .q(Aw_out),
        .d(Aw_in),
        .clk,
        .reset
    );

    // address / alu computation
    D_FF #(64) alu_addr_output(
        .q(ALUResult_out),
        .d(ALUResult_in),
        .clk,
        .reset
    );

    // Dout
    D_FF #(64) dout_update(
        .q(Dout_out),
        .d(Dout_in),
        .clk,
        .reset
    );

    // writeback control
    writeback_control_reg mem_wb_w(
        .MemtoReg_out,
        .MemtoReg_in,
        .RegWrite_out,
        .RegWrite_in,
        .clk,
        .reset
    );
endmodule


// === Control Register Blocks ===

// writeback, only need memtoreg + regwrite to figure out data source and if we are writing
module writeback_control_reg(
    output logic [1:0] MemtoReg_out,
    output logic RegWrite_out,
    input logic clk,
    input logic reset,
    input logic [1:0] MemtoReg_in,
    input logic RegWrite_in
    );

    // MemtoReg
    D_FF #(2) memtoreg_update(
        .q(MemtoReg_out),
        .d(MemtoReg_in),
        .clk,
        .reset
    );

    // RegWrite
    D_FF #(1) regwrite_update(
        .q(RegWrite_out),
        .d(RegWrite_in),
        .clk,
        .reset
    );
endmodule

// mem, are we reading (?) are we writing (?)
module memory_control_reg(
    output logic MemRead_out,
    output logic MemWrite_out,
    input logic clk,
    input logic reset,
    input logic MemRead_in,
    input logic MemWrite_in
    );

    // MemRead
    D_FF #(1) read(
        .q(MemRead_out),
        .d(MemRead_in),
        .clk,
        .reset
    );

    // MemWrite
    D_FF #(1) write(
        .q(MemWrite_out),
        .d(MemWrite_in),
        .clk,
        .reset
    );
endmodule

/*
    ex:
    (1) branch stuff -> are we branching (?) what kind (?) to reg or no (?)
    **** TODO: remove branch stuff from ex since it's been moved into ID for reducing cycle penalty
    (2) ALU stuff -> source of 2nd operand (?) what ALU operation (?    )
*/
module execute_control_reg(
    output logic UncondBr_out,
    output logic BrTaken_out,
    output logic [2:0] ALUOp_out,
    output logic [1:0] ALUSrc_out,
    output logic FlagWrite_out,
    output logic BrReg_out,
    input logic clk,
    input logic reset,
    input logic [2:0] ALUOp_in,
    input logic [1:0] ALUSrc_in,
    input logic UncondBr_in,
    input logic BrTaken_in,
    input logic FlagWrite_in,
    input logic BrReg_in

    );

    // UncondBr
    D_FF #(1) uncondbr_update(
        .q(UncondBr_out),
        .d(UncondBr_in),
        .clk,
        .reset
    );

    // BrTaken
    D_FF #(1) brtaken_update(
        .q(BrTaken_out),
        .d(BrTaken_in),
        .clk,
        .reset
    );

    // ALUSrc
    D_FF #(2) source(
        .q(ALUSrc_out),
        .d(ALUSrc_in),
        .clk,
        .reset
    );

    // ALUOp
    D_FF #(3) op(
        .q(ALUOp_out),
        .d(ALUOp_in),
        .clk,
        .reset
    );

    // FlagWrite
    D_FF #(1) flags(
        .q(FlagWrite_out),
        .d(FlagWrite_in),
        .clk,
        .reset
    );

    // BrReg
    D_FF #(1) brreg_update(
        .q(BrReg_out),
        .d(BrReg_in),
        .clk,
        .reset
    );
endmodule