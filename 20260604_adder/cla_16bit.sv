// 1. 하위 모듈인 cla_4bit를 맨 위에 먼저 정의합니다.
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


// 2. 이어서 16비트 탑 모듈을 작성합니다.
module cla_16bit (
    input  logic [15:0] a,
    input  logic [15:0] b,
    input  logic        c_in,
    output logic [15:0] sum,
    output logic        c_out
);

    logic [2:0] c;

    cla_4bit u_cla0 (.a(a[3:0]),   .b(b[3:0]),   .c_in(c_in), .sum(sum[3:0]),   .c_out(c[0]));
    cla_4bit u_cla1 (.a(a[7:4]),   .b(b[7:4]),   .c_in(c[0]), .sum(sum[7:4]),   .c_out(c[1]));
    cla_4bit u_cla2 (.a(a[11:8]),  .b(b[11:8]),  .c_in(c[1]), .sum(sum[11:8]),  .c_out(c[2]));
    cla_4bit u_cla3 (.a(a[15:12]), .b(b[15:12]), .c_in(c[2]), .sum(sum[15:12]), .c_out(c_out));

endmodule
