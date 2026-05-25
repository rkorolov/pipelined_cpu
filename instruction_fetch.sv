`timescale 1ns/10ps

module instruction_fetch(
    output logic [63:0] plusFour,
    output logic [63:0] PC,
    output logic [31:0] Instr,
    input logic [63:0] branchPC,
    input logic PCWrite,
    input logic BrTaken,
    input logic clk,
    input logic reset
    );

    instructmem imem (
        .address(PC), 
        .instruction(Instr),
        .clk(clk)
    );

    // add four
    alu add_four(
        .A(PC),
        .B(64'd4),
        .cntrl(3'b010),
        .result(plusFour),
        .negative(),
        .zero(),
        .overflow(),
        .carry_out()
    );

    logic [63:0] nextPC;
    mux2_1_Nbit #(64) update_PC(
        .out(nextPC),
        .i0(plusFour),
        .i1(branchPC),
        .sel(BrTaken)
    );

    // PC write - load hazard
    logic [63:0] PC_wire;
    mux2_1_Nbit #(64) pc_write(
        .sel(PCWrite), 
        .i0(PC), // might need current PC for this
        .i1(nextPC), 
        .out(PC_wire)
    );

    // clock PC
    D_FF #(64) PC_DFF(
        .q(PC),
        .d(PC_wire),
        .reset(reset),
        .clk(clk)
    );

endmodule