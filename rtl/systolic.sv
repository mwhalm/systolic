module systolic #(
	parameter N = 8,
	parameter IA_WIDTH = 8,
	parameter W_WIDTH = 8,
	parameter OA_WIDTH = 24,
	parameter CONV_IA_ROW_SIZE = 16,
	parameter FILTER_SIZE = 8,
	parameter CONV_TILE_SIZE,
	parameter CONV_OUT_SIZE = CONV_IA_ROW_SIZE - FILTER_SIZE + 1
)(
	input clk,
	input rst,
	input start,
	input logic [1 : 0] method,
	input logic signed [IA_WIDTH - 1 : 0] ia_in [0 : N - 1][0 : N - 1],
	input logic signed [W_WIDTH - 1 : 0] w_in [0 : N - 1][0 : N - 1],
	input logic signed [IA_WIDTH - 1 : 0] conv_ia_in [0 : CONV_TILE_SIZE][0 : CONV_IA_ROW_SIZE - 1],
	input logic signed [W_WIDTH - 1 : 0] filter_in [0 : FILTER_SIZE - 1][0 : FILTER_SIZE - 1],

	output done,
	output logic signed [OA_WIDTH - 1 : 0] oa_out [0 : N - 1][0 : N - 1],
	output logic signed [OA_WIDTH - 1 : 0] conv_out [0 : N - 1][0 : CONV_OUT_SIZE - 1]
);
	
	localparam WS = 2'b00;
	localparam IS = 2'b01;
	localparam OS = 2'b10;
	localparam RS = 2'b11;

	logic signed [IA_WIDTH - 1 : 0] row_w [0 : N - 1][0 : N];
	logic signed [W_WIDTH - 1 : 0] col_w [0 : N][0 : N - 1];
	logic signed [IA_WIDTH - 1 : 0] ia_t [0 : N - 1][0 : N - 1];
	logic signed [W_WIDTH - 1 : 0] w_t [0 : N - 1][0 : N - 1];
	logic signed [IA_WIDTH - 1:0] buf_in [0 : N - 1][0 : N - 1];
	logic signed [IA_WIDTH - 1:0] load_in [0 : N - 1][0 : N - 1];
	logic signed [IA_WIDTH - 1:0] row_buf_out [0 : N - 1];
	logic signed [W_WIDTH - 1:0] col_buf_out [0 : N - 1];
	logic signed [OA_WIDTH - 1:0] conv_buf_out [0 : N - 1];
	logic signed [OA_WIDTH - 1:0] pe_w [0 : N][0 : N - 1];

	logic conv_load [0 : N - 1];
	logic en_h [0 : N - 1][0 : N];
	logic en_v [0 : N][0 : N - 1];
	logic [$clog2(2 * N + 1) : 0] cycles;
	logic [1 : 0] dataflow;
	logic fsm_en, load, conv_buf_en, conv_buf_clr;

	genvar i, j;

	// systolic array controller
	sys_ctrl #(
		.N(N),
		.CONV_OUT_SIZE(CONV_OUT_SIZE)
	) fsm_ctrl (
		.clk(clk),
		.rst(rst),
		.start(start),
		.method(method),

		.load(load),
		.en(fsm_en),
		.done(done),
		.conv_buf_en(conv_buf_en),
		.conv_buf_clr(conv_buf_clr),
		.df(dataflow)
	);

	// top corner of array receives the FSM enable signal and sends it to other PEs
	assign en_v[0][0] = fsm_en;
	assign en_h[0][0] = fsm_en;

	// connect IA buf to wire connected to column 0 PEs
	// set starting partial OA to 0
	generate
		for(i = 0; i < N; i++) begin : init
			assign row_w[i][0] = row_buf_out[i];
			assign col_w[0][i] = col_buf_out[i];
			assign pe_w[0][i] = '0;
		end : init
	endgenerate

	// instatntiate PEs
	generate
		for(i = 0; i < N; i++) begin : pe_row
			for(j = 0; j < N; j++) begin : pe_col
				pe #(
					.IA_WIDTH(IA_WIDTH),
					.W_WIDTH(W_WIDTH),
					.OA_WIDTH(OA_WIDTH),
					.CONV_IA_ROW_SIZE(CONV_IA_ROW_SIZE),
					.FILTER_SIZE(FILTER_SIZE)
				) pe_block (
					.clk(clk),
					.rst(rst),
					.en_top(en_v[i][j]),
					.en_left(en_h[i][j]),
					.load(load),
					.dataflow(dataflow),
					.filter_row_in(filter_in[i]),
					.conv_row_in(conv_ia_in[i + j]),
					.row_in(row_w[i][j]),
					.col_in(col_w[i][j]),
					.load_val(load_in[i][j]),
					.pe_in(pe_w[i][j]),

					.en_right(en_h[i][j + 1]),
					.en_bot(en_v[i + 1][j]),
					.row_out(row_w[i][j + 1]),
					.col_out(col_w[i + 1][j]),
					.pe_out(pe_w[i + 1][j])
				);
			end : pe_col
		end : pe_row
	endgenerate

	// transpose matrices
	generate
		for(i = 0; i < N; i++) begin : ia_t_r
			for(j = 0; j < N; j++) begin : ia_t_c
				assign ia_t[i][j] = ia_in[j][i];
				assign w_t[i][j] = w_in[j][i];
			end : ia_t_c
		end : ia_t_r
	endgenerate

	// mux buffer inputs
	generate
		for(i = 0; i < N; i++) begin : mux_buf_in
			assign buf_in[i] = (dataflow[1] == 1'b0) ? ((dataflow[0] == 1'b0) ? ia_t[i] : w_in[i]) : ia_in[i];
		end : mux_buf_in
	endgenerate

	// mux static load value (weight and input stationary)
	generate
		for(i = 0; i < N; i++) begin : mux_load_vals
			assign load_in[i] = (dataflow[1] == 1'b0) ? ((dataflow[0] == 1'b0) ? w_in[i] : ia_t[i]) : '{default: '0};
		end : mux_load_vals
	endgenerate

	// row_buffers connected with ripple carry enable signals
	generate
		for(i = 0; i < N; i++) begin : row_bufs
			stream_buf #(
				.N(N),
				.WIDTH(IA_WIDTH)
			) row_buf (
				.clk(clk),
				.rst(rst),
				.en(en_v[i][0]),
				.load(load),
				.in(buf_in[i]),
				.buf_out(row_buf_out[i])
			);
		end : row_bufs
	endgenerate

	// col_buffers connected with ripple carry enable signals
	generate
		for(i = 0; i < N; i++) begin : col_bufs
			stream_buf #(
				.N(N),
				.WIDTH(W_WIDTH)
			) col_buf (
				.clk(clk),
				.rst(rst),
				.en(en_h[0][i]),
				.load(load),
				.in(w_t[i]),
				.buf_out(col_buf_out[i])
			);
		end : col_bufs
	endgenerate

	generate
		for(i = 0; i < N; i++) begin : conv_bufs
			conv_buf #(
				.CONV_OUT_SIZE(CONV_OUT_SIZE),
				.WIDTH(OA_WIDTH)
			) conv_bufs (
				.clk(clk),
				.rst(rst),
				.en(conv_buf_en),
				.load(conv_load[i]),
				.clr(conv_buf_clr),
				.in(pe_w[N][i]),
				.buf_out(conv_buf_out[i])
			);
		end : conv_bufs
	endgenerate

	generate
		for(i = 0; i < N; i++) begin
			assign conv_load[i] = (cycles >= (N + i) && cycles < (N + i + CONV_OUT_SIZE));
		end
	endgenerate

	logic [7 : 0] conv_wr_index;

	// cycle counter for writing
	always_ff @(posedge clk) begin
		cycles <= fsm_en ? cycles + 1'b1 : '0;
		conv_wr_index <= (conv_buf_en && conv_wr_index < CONV_OUT_SIZE) ? conv_wr_index + 1'b1 : '0;
	end
	
	// write output values
	always_ff @(posedge clk) begin
		if(method != RS) begin
			for(int i = 0; i < N; i++) begin : out_row
				for(int j = 0; j < N; j++) begin : out_col
					if(cycles == (i + j + N)) begin
						unique case(method)
							WS : oa_out[i][j] <= pe_w[N][j];
							IS : oa_out[j][i] <= pe_w[N][j];
							OS : oa_out[i][j] <= pe_w[i + 1][j];
							default : oa_out[i][j] <= 'x;
						endcase
					end
				end : out_col
			end : out_row
		end else begin
			for(int i = 0; i < N; i++) begin
				conv_out[i][conv_wr_index] <=  conv_buf_en ? conv_buf_out[i] : conv_out[i][conv_wr_index];
			end
		end
	end
endmodule