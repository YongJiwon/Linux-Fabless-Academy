module full_adder (
    input  logic a,
    input  logic b,
    input  logic c_in,
    output logic c_out,
    output logic sum
);

    logic s0, c0, c1;

    half_adder U_HF0 (
        .a   (a),
        .b   (b),
        .sum (s0),
        .co  (c0)
    );

    half_adder U_HF1 (
        .a   (s0),
        .b   (c_in),
        .sum (sum),
 	.co  (c1)
    );

    assign c_out = c0 | c1;

endmodule
