module d_ff(
	input clk,
	input rst,
	input [15:0] d,
	output [15:0] q
);

	always @(posedge clk or posedge rst) begin
		if(rst) begin
			q <= 4'h0000;
		end else begin
			q <= d;
		end
	end

endmodule

