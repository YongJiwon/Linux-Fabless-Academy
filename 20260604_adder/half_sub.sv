module half_sub(
	input a,
	input b,
	input b_in,
	output logic b_out,
	output logic diff
);


assign diff = a^b;
assign b_out = ~a&b;


endmodule

