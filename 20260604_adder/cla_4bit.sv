module cla_4bit (
    input  logic [3:0] a,
    input  logic [3:0] b,
    input  logic       c_in,
    output logic [3:0] sum,
    output logic       c_out
);

    logic [3:0] p, g;
    logic [4:0] c;

    assign c[0] = c_in;

    assign g = a & b;
    assign p = a ^ b;

    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
    assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0]);
    assign c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & c[0]);

   
    assign sum   = p ^ c[3:0];
    assign c_out = c[4];

endmodule
