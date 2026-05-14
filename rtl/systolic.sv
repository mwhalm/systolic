module systolic #(
	parameter N = 8,
	parameter IA_WIDTH = 8,
	parameter W_WIDTH = 8,
	parameter OA_WIDTH = 24
)(
	input clk,
	input rst,
	input start,
	input logic signed [IA_WIDTH - 1 : 0] ia_in [0 : N - 1][0 : N - 1],
	input logic signed [W_WIDTH - 1 : 0] w_in [0 : N - 1][0 : N - 1],
	
	output done,
	output logic signed [OA_WIDTH - 1 : 0] oa_out [0 : N - 1][0 : N - 1]
);
	
	logic signed [IA_WIDTH - 1 : 0] ia_in_w [0 : N - 1][0 : N];
	logic signed [IA_WIDTH - 1 : 0] ia_t [0 : N - 1][0 : N - 1];
	logic signed [IA_WIDTH - 1:0] ia_buf_out [0 : N - 1];
	logic signed [OA_WIDTH - 1:0] oa_w [0 : N][0 : N - 1];

	logic en_h [0 : N - 1][0 : N];
	logic en_v [0 : N][0 : N - 1];
	logic [$clog2(2 * N + 1) : 0] cycles;
	logic fsm_en, load;

	genvar i, j;

	// instantiate systolic array controller
	sys_ctrl #(
		.N(N)
	) fsm_ctrl (
		.clk(clk),
		.rst(rst),
		.start(start),
		.load(load),
		.en(fsm_en),
		.done(done)
	);

	// top corner of array receives the FSM enable signal and sends it to other PEs
	assign en_v[0][0] = fsm_en;
	assign en_h[0][0] = fsm_en;

	// connect IA buf to wire connected to column 0 PEs
	// set starting partial OA to 0
	generate
		for(i = 0; i < N; i++) begin : init
			assign ia_in_w[i][0] = ia_buf_out[i];
			assign oa_w[0][i] = '0;
		end : init
	endgenerate

	// instatntiate PEs
	generate
		for(i = 0; i < N; i++) begin : pe_row
			for(j = 0; j < N; j++) begin : pe_col
				pe #(
					.IA_WIDTH(IA_WIDTH),
					.W_WIDTH(W_WIDTH),
					.OA_WIDTH(OA_WIDTH)
				) pe_block (
					.clk(clk),
					.rst(rst),
					.en_top(en_v[i][j]),
					.en_left(en_h[i][j]),
					.load_weight(load),
					.ia_in(ia_in_w[i][j]),
					.w_in(w_in[i][j]),
					.oa_in(oa_w[i][j]),

					.en_right(en_h[i][j + 1]),
					.en_bot(en_v[i + 1][j]),
					.ia_out(ia_in_w[i][j + 1]),
					.oa_out(oa_w[i + 1][j])
				);
			end : pe_col
		end : pe_row
	endgenerate

	// transpose input matrix
	generate
		for(i = 0; i < N; i++) begin : ia_t_r
			for(j = 0; j < N; j++) begin : ia_t_c
				assign ia_t[i][j] = ia_in[j][i];
			end : ia_t_c
		end : ia_t_r
	endgenerate

	// instantiate ia_row_buffers connected with ripple carry enable signals
	generate
		for(i = 0; i < N; i++) begin : ia_bufs
			ia_buf #(
				.N(N),
				.WIDTH(IA_WIDTH)
			) ia_row_buf (
				.clk(clk),
				.rst(rst),
				.en(en_v[i][0]),
				.load(load),
				.ia_in(ia_t[i]),
				.buf_out(ia_buf_out[i])
			);
		end : ia_bufs
	endgenerate

	always_ff @(posedge clk) begin
		if(fsm_en)
			cycles <= cycles + 1'b1;
		else
			cycles <= '0;
	end

	// assign output weights
	generate 
		for(i = 0; i < N; i++) begin : out_row
			for(j = 0; j < N; j++) begin : out_col
				always_ff @(posedge clk) begin
					if(cycles == (i + j + N + 1))
						oa_out[i][j] <= oa_w[N][j];
				end
			end : out_col
		end : out_row
	endgenerate
endmodule