module operand_fetch(
    input logic [31:0] Instr,
    output logic [4:0] Rd,
    output logic [4:0] Rm,
    output logic [4:0] Rn,
    output logic [63:0] SEAAddr9,
    output logic [63:0] SEAAddr19,
    output logic [63:0] SEAAddr26,
    output logic [63:0] ALUImm
    );

    // wiring for regfile inputs
    assign Rd = Instr[4:0];
    assign Rm = Instr[20:16];
    assign Rn = Instr[9:5];
    
    logic [8:0] DAddr9;
    logic [11:0] Immead;

    assign DAddr9 = Instr[20:12]; // load/store
    assign Immead = Instr[21:10]; // i-type

    logic [18:0] branchAddr19;
    logic [25:0] branchAddr26;
    
    assign branchAddr19 = Instr[23:5]; // cond branch
    assign branchAddr26 = Instr[25:0]; // uncond branch

    // sign extend addresses
    sign_extend address(
        .branchAddr26,
        .branchAddr19,
        .DAddr9,
        .SEAAddr26,
        .SEAAddr19,
        .SEAAddr9
    );

    // zero extend Immead
    zero_extend ze(
        .addr(Immead),
        .ZEAddr(ALUImm)
    );

    
endmodule