`timescale 1ns/10ps

// OR-s 16 bits together, then returns the inverted bit
module nor16(out, in);
    output logic       out;
    input logic [15:0] in;

    logic o0out, o1out, o2out, o3out, o4out;
    
    or #(50ps) (o0out, in[3], in[2], in[1], in[0]);
    or #(50ps) (o1out, in[7], in[6], in[5], in[4]);
    or #(50ps) (o2out, in[11], in[10], in[9], in[8]);
    or #(50ps) (o3out, in[15], in[14], in[13], in[12]);

    or #(50ps) (o4out, o0out, o1out, o2out, o3out);
    not #(50ps) (out, o4out);
endmodule


module nor64(out, in);
    output logic       out;
    input logic [63:0] in;

    logic n0out, n1out, n2out, n3out;

    nor16 n0(n0out, in[15:0]);
    nor16 n1(n1out, in[31:16]);
    nor16 n2(n2out, in[47:32]);
    nor16 n3(n3out, in[63:48]);

    and #(50ps) a0(out, n0out, n1out, n2out, n3out);
endmodule