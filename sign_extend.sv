`timescale 1ns/10ps

module sign_extend (
    input logic [25:0] branchAddr26,
    input logic [18:0] branchAddr19,
    input logic [8:0] DAddr9,
    output logic [63:0] SEAAddr26,
    output logic [63:0] SEAAddr19,
    output logic [63:0] SEAAddr9
);

    assign SEAAddr26 = {{38{branchAddr26[25]}}, branchAddr26};
    assign SEAAddr19 = {{45{branchAddr19[18]}}, branchAddr19};
    assign SEAAddr9 = {{55{DAddr9[8]}}, DAddr9};

endmodule

// alu imm
module zero_extend(
    input logic [11:0] addr,
    output logic [63:0] ZEAddr
);
    assign ZEAddr = {{52{1'b0}}, addr};
endmodule