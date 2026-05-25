`timescale 1ns/10ps

/*
    Generates control signals using flags & the instruction

    Reg2Loc   -> what register do you want to read / what comes out of ReadData2 -- (1): Rm or (0): Rd
    ALUSrc    -> is my source from reg file, a sign extended address, or a zero extended address
    MemtoReg  -> are you going from memory to register, PC+4 to a register, or from the ALU to a register
    RegWrite  -> are we writing data to the reg file - yes (1) or no (0)
    MemWrite  -> are we writing data to the memory - yes (1) or no (0)
    Branch    -> are we branching - yes (1) or no (0)
    UncondBr  -> is this an unconditional branch - yes (1) or no (0)
    ALUOp     -> ADD:010 | SUB:011 | BYBASSB:000
    MemRead   -> are we reading from memory - yes (1) or no (0)
    FlagWrite -> are we generating flags - - yes (1) or no (0)
    BrReg    -> are we branching to a register address (BR) - yes (1) or no (0)

*/

module control(
    input logic [31:0] Instr,
    input logic ALUZero,
    input logic Negative,
    input logic Overflow,
    input logic [63:0] Db,
    output logic Reg2Loc,
    output logic [1:0] ALUSrc,
    output logic [1:0] MemtoReg,
    output logic RegWrite,
    output logic MemWrite,
    output logic BrTaken,
    output logic UncondBr,
    output logic [2:0] ALUOp,
    output logic MemRead,
    output logic FlagWrite,
    output logic BrReg
    );

    always_comb begin
        casez (Instr[31:21])
            11'b1001000100?: begin  // ADDI
                Reg2Loc =  1'b0; // don't care since we are using an immd for second operand
                ALUSrc =   2'b01; // choose immeadiate
                MemtoReg = 2'b00;
                RegWrite = 1'b1;
                MemWrite = 1'b0;
                BrTaken =  1'b0;
                UncondBr = 1'b0; // don't care
                ALUOp =    3'b010;
                MemRead =  1'b0;
                FlagWrite = 1'b0; 
                BrReg = 1'b0;
            end

            11'b10001011000: begin // ADD 
                Reg2Loc =  1'b1;
                ALUSrc =   2'b00;
                MemtoReg = 2'b00;
                RegWrite = 1'b1;
                MemWrite = 1'b0;
                BrTaken =  1'b0;
                UncondBr = 1'b0; // don't care
                ALUOp =    3'b010;
                MemRead =  1'b0;
                FlagWrite = 1'b0; 
                BrReg = 1'b0;
            end

            11'b11001011000: begin  // SUB
                Reg2Loc =  1'b1;
                ALUSrc =   2'b00;
                MemtoReg = 2'b00;
                RegWrite = 1'b1;
                MemWrite = 1'b0;
                BrTaken =  1'b0;
                UncondBr = 1'b0; // don't care
                ALUOp =    3'b011;
                MemRead =  1'b0;
                FlagWrite = 1'b0; 
                BrReg = 1'b0;
            end

            11'b10101011000: begin  // ADDS
                Reg2Loc =  1'b1;
                ALUSrc =   2'b00;
                MemtoReg = 2'b00;
                RegWrite = 1'b1;
                MemWrite = 1'b0;
                BrTaken =  1'b0;
                UncondBr = 1'b0; // don't care
                ALUOp =    3'b010;
                MemRead =  1'b0;
                FlagWrite = 1'b1; 
                BrReg = 1'b0;
            end

            11'b11101011000: begin  // SUBS
                Reg2Loc =  1'b1;
                ALUSrc =   2'b00;
                MemtoReg = 2'b00;
                RegWrite = 1'b1;
                MemWrite = 1'b0;
                BrTaken =  1'b0;
                UncondBr = 1'b0; // don't care
                ALUOp =    3'b011;
                MemRead =  1'b0;
                FlagWrite = 1'b1; 
                BrReg = 1'b0;
            end

            11'b11111000010: begin  // LDUR
                Reg2Loc =  1'b0; // don't care
                ALUSrc =   2'b10; // need to compute mem address
                MemtoReg = 2'b01;
                RegWrite = 1'b1; // writing from mem into reg
                MemWrite = 1'b0;
                BrTaken =  1'b0;
                UncondBr = 1'b0; // don't care
                ALUOp =    3'b010; 
                MemRead =  1'b1;
                FlagWrite = 1'b0; // don't care
                BrReg = 1'b0;
            end

            11'b11111000000: begin  // STUR
                Reg2Loc =  1'b0; // need full mem bits
                ALUSrc =   2'b10; // need to compute mem address *dbl check mux inputs
                MemtoReg = 2'b00; // don't care, not putting anything in reg file
                RegWrite = 1'b0; 
                MemWrite = 1'b1;
                BrTaken =  1'b0;
                UncondBr = 1'b0; // don't care
                ALUOp =    3'b010;
                MemRead =  1'b0; 
                FlagWrite = 1'b0; // don't care
                BrReg = 1'b0;
            end

            11'b10110100???: begin  // CBZ
                Reg2Loc =  1'b0;   // need Rd to get B to check for zero
                ALUSrc =   2'b00;  // don't care
                MemtoReg = 2'b00;  // don't care
                RegWrite = 1'b0;
                MemWrite = 1'b0;
                UncondBr = 1'b0;   // conditional
                ALUOp =    3'b000; // don't care
                MemRead =  1'b0;
                FlagWrite = 1'b0;  // don't care
                BrReg = 1'b0;
                BrTaken = (Db == 64'b0); // directly checking if register is zero

            end

            11'b01010100???: begin  // BLT
                Reg2Loc =  1'b0; // don't care
                ALUSrc =   2'b00; // don't care
                MemtoReg = 2'b00; // don't care
                RegWrite = 1'b0; 
                MemWrite = 1'b0;
                UncondBr = 1'b0; // condition must pass
                ALUOp =    3'b000; // don't care
                MemRead =  1'b0;
                FlagWrite = 1'b0; // don't care
                BrReg = 1'b0;
                BrTaken = Negative ^ Overflow;
            end

            11'b100101?????: begin  // BL
                Reg2Loc =  1'b0; // don't care
                ALUSrc =   2'b00; // don't care
                MemtoReg = 2'b10; // write PC+4 into reg file to link for return address
                RegWrite = 1'b1; // write PC+4 into X30
                MemWrite = 1'b0;
                BrTaken =  1'b1; // uncond branch
                UncondBr = 1'b1; // ^
                ALUOp =    3'b000; // don't care
                MemRead =  1'b0;
                FlagWrite = 1'b0; // don't care
                BrReg = 1'b0;
            end

            11'b11010110000: begin  // BR
                Reg2Loc =  1'b0; // don't care
                ALUSrc =   2'b00; // don't care
                MemtoReg = 2'b00; 
                RegWrite = 1'b0;
                MemWrite = 1'b0;
                BrTaken =  1'b1; // uncond branch to register
                UncondBr = 1'b1; // ^
                ALUOp =    3'b000; // don't care
                MemRead =  1'b0;
                FlagWrite = 1'b0; // don't care
                BrReg = 1'b1; // branch to register

            end

            11'b000101?????: begin  // B
                Reg2Loc =  1'b0; // don't care
                ALUSrc =   2'b00; // don't care
                MemtoReg = 2'b00; // don't care
                RegWrite = 1'b0; 
                MemWrite = 1'b0;
                BrTaken =  1'b1; // uncond branch
                UncondBr = 1'b1; // ^
                ALUOp =    3'b000; // don't care
                MemRead =  1'b0;
                FlagWrite = 1'b0; // don't care
                BrReg = 1'b0;
            end

            default: begin
                Reg2Loc =  1'b0;
                ALUSrc =   2'b00;
                MemtoReg = 2'b00;
                RegWrite = 1'b0; 
                MemWrite = 1'b0;
                BrTaken =  1'b0; 
                UncondBr = 1'b0; 
                ALUOp =    3'b000; 
                MemRead =  1'b0;
                FlagWrite = 1'b0; 
                BrReg = 1'b0;
            end
        endcase
    end

endmodule
