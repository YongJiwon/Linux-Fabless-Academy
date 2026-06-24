module full_sub(
	input a,
	input b,
	input b_in,
	output logic diff,
	output logic b_out
);




logic d1, b1, b2;
i

half_sub U_HB0(
	.a(a),
	.b(b),
	.b_in(d1),
	.b_out(b1)

);


half_sub U_HB1(
	.a(a),
	.b(b),
	.b_in(diff),
	.b_out(b2)
);




assign b_out =b1|b2;


endmodule
