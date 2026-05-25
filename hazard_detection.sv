`timescale 1ns/10ps

// stall & freeze logic
module hazard_detection(
    output logic PCWrite,
    output logic if_id_write,
    output logic Flush,
    input logic id_ex_MemRead,
    input logic [4:0] id_ex_Rd,
    input logic [4:0] if_id_Rn,
    input logic [4:0] if_id_Rm,
    input logic [31:0] if_id_Instr,
    input logic id_ex_RegWrite,
    input logic ex_mem_RegWrite,
    input logic [4:0] ex_mem_Rd
    );


    always_comb begin

        // stall on load-use hazard -> load res needed by the next instr
        if (id_ex_MemRead && ((id_ex_Rd == if_id_Rn) || (id_ex_Rd == if_id_Rm))) begin
            // STALL: freeze PC + IF/ID, inject NOP bubble into ID/EX
            PCWrite     = 1'b0;
            if_id_write = 1'b0;
            Flush       = 1'b1;
        
        // stall if cbz is using a target register that is being written to in prev 2 instructions, priority is newer value
        end else if ((if_id_Instr[31:24] == 8'b10110100) && id_ex_RegWrite && (id_ex_Rd != 5'd31) && (id_ex_Rd == if_id_Instr[4:0])) begin
            // STALL -- writing a value into reg right before directly checking if for CBZ
            PCWrite     = 1'b0;
            if_id_write = 1'b0;
            Flush       = 1'b1;
        end else if ((if_id_Instr[31:24] == 8'b10110100) && ex_mem_RegWrite && (ex_mem_Rd != 5'd31) && (ex_mem_Rd == if_id_Instr[4:0])) begin
            PCWrite     = 1'b0;
            if_id_write = 1'b0;
            Flush       = 1'b1;
        end else begin
            // no stall
            PCWrite     = 1'b1;
            if_id_write = 1'b1;
            Flush       = 1'b0;
        end

    end

endmodule