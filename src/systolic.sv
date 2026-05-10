module systolic #(
	parameter N = 8,
	parameter IA_WIDTH = 8,
	parameter W_WIDTH = 8,
	parameter OA_WIDTH = 20
)(
	input clk,
	input rst,

	input logic signed [IA_WIDTH - 1 : 0] ia_in [0 : N - 1],
	input logic signed [W_WIDTH - 1 : 0] w_in [0 : N - 1][0 : N - 1],
	output logic signed [OA_WIDTH - 1 : 0] oa_out [0 : N][0 : N]
);
	
	logic signed [IA_WIDTH - 1 : 0] ia_in_w [0 : N - 1][0 : N - 1];
	logic signed [OA_WIDTH - 1:0] oa_w [0 : N][0 : N - 1];
	logic en_h [0 : N - 1][0 : N];
	logic en_v [0 : N][0 : N - 1];

	genvar i, j;
	generate
		for(i = 0; i < N; i++) begin
			assign ia_in_w[i][0] = ia_in[i];
			assign oa_w[0][i] = '0;
		end
	endgenerate

	generate
		for(i = 0; i < N; i++) begin
			for(j = 0; j < N; j++) begin
				pe #(
					.IA_WIDTH(IA_WIDTH),
					.W_WIDTH(W_WIDTH),
					.OA_WIDTH(OA_WIDTH)
				) pe_block (
					.clk(clk),
					.rst(rst),
					.en_top(en_v[i][j]),
					.en_left(en_h[i][j]),
					.load_weight(),
					.ia_in(ia_in_w[i][j]),
					.w_in(w_in[i][j]),
					.oa_in(oa_w[i][j]),

					.en_right(en_h[i][j + 1]),
					.en_bot(en_v[i + 1][j]),
					.ia_out(ia_in_w[i][j + 1]),
					.oa_out(oa_w[i + 1][j])
				);
			end
		end
	endgenerate

	generate 
		for(i = 0; i < N; i++) begin
			assign oa_out[N - 1][i] = oa_w[N - 1][i]
		end
	endgenerate
endmodule