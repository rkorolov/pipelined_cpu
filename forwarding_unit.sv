`timescale 1ns/10ps

// Forwarding Logic 
module forwarding_unit(
    output logic [1:0] ForwardA,
    output logic [1:0] ForwardB,
    input logic [4:0] id_ex_Rn,
    input logic [4:0] id_ex_Rm,
    input logic [4:0] ex_mem_Rd,
    input logic [4:0] mem_wb_Rd,
    input logic ex_mem_RegWrite,
    input logic mem_wb_RegWrite

);
    always_comb begin
        
        // Register write Forwarding
        // A -> Rn == Rd
        if (ex_mem_RegWrite && (ex_mem_Rd != 5'd31) && (ex_mem_Rd == id_ex_Rn)) begin // case 1 A
            ForwardA = 2'b10; // mem stage
        end else if (mem_wb_RegWrite && (mem_wb_Rd != 5'd31) && (mem_wb_Rd == id_ex_Rn)) begin // case 2 -> only in the case of no EX/MEM forwarding
            ForwardA = 2'b01; // wb stage
        end else begin
            ForwardA = 2'b00; // no forward
        end

        // B -> Rm == Rd
        if (ex_mem_RegWrite && (ex_mem_Rd != 5'd31) && (ex_mem_Rd == id_ex_Rm)) begin // case 1 B
            ForwardB = 2'b10;
        end else if (mem_wb_RegWrite && (mem_wb_Rd != 5'd31) && (mem_wb_Rd == id_ex_Rm)) begin // case 2
            ForwardB = 2'b01;
        end else begin
            ForwardB = 2'b00;
        end
    end
endmodule