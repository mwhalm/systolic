module pe #(
	parameter IA_WIDTH = 8,
	parameter W_WIDTH = 8,
	parameter OA_WIDTH = 2 * IA_WIDTH + 8,
	parameter CONV_IA_ROW_SIZE = 16,
	parameter FILTER_SIZE = 8
)(
	input logic clk,
	input logic rst,
	input logic en_top,
	input logic en_left,
	input logic load,
	input logic [1 : 0] dataflow,
	input logic signed [W_WIDTH - 1 : 0] filter_row_in [0 : FILTER_SIZE - 1],
	input logic signed [IA_WIDTH - 1 : 0] conv_row_in [0 : CONV_IA_ROW_SIZE - 1],
	input logic signed [IA_WIDTH - 1 : 0] row_in,
	input logic signed [W_WIDTH - 1 : 0] col_in,
	input logic signed [IA_WIDTH - 1 : 0] load_val,
	input logic signed [OA_WIDTH - 1 : 0] pe_in,

	output logic en_right,
	output logic en_bot,
	output logic signed [IA_WIDTH - 1 : 0] row_out,
	output logic signed [W_WIDTH - 1 : 0] col_out,
	output logic signed [OA_WIDTH - 1 : 0] pe_out
);
	localparam WS = 2'b00;
	localparam IS = 2'b01;
	localparam OS = 2'b10;
	localparam RS = 2'b11;
	localparam MAX_LOW_INDEX = CONV_IA_ROW_SIZE - FILTER_SIZE;

	logic signed [W_WIDTH - 1 : 0] static_val;
	logic signed [OA_WIDTH - 1 : 0] acc;
	logic signed [W_WIDTH - 1 : 0] filter_row [0 : FILTER_SIZE - 1];
	logic signed [OA_WIDTH - 1 : 0] rs_sum;

	logic [$clog2(MAX_LOW_INDEX) : 0] index;
	logic en, ws_is, os, rs;

	assign en = en_top | en_left;
	assign ws_is = (dataflow[1] == 1'b0);
	assign os = (dataflow == 2'b10);
	assign rs = (dataflow == 2'b11);

	always_ff @(posedge clk) begin
		if (!rst) begin
			row_out <= '0;
			col_out <= '0;
			pe_out <= '0;
			acc <= '0;
			en_right <= '0;
			en_bot <= '0;
			static_val <= load_val;
			index <= '0;
			for(int i = 0; i < FILTER_SIZE; i++)
				filter_row[i] <= '0;
		end else begin
			en_right <= en;
			en_bot <= en;
			
			if (load && ws_is)
				static_val <= load_val;
			else if (load && os)
				pe_out <= '0;
			else if (load && rs) begin
				pe_out <= '0;
				for(int i = 0; i < FILTER_SIZE; ++i) begin
					filter_row[i] <= filter_row_in[i];
				end
			end

			if(en) begin
				row_out <= row_in;
				unique case(dataflow)
					WS, IS : pe_out <= pe_in + row_in * static_val;
					OS : begin
						col_out <= col_in;
						pe_out <= pe_out + row_in * col_in;
					end
					RS : begin
						pe_out <= rs_sum + pe_in;
						index <= index + 1'b1;
					end
				endcase
			end
		end
	end

	always_comb begin
		rs_sum = '0;
		for(int i = 0; i < FILTER_SIZE; i++) begin
			rs_sum += filter_row[i] * conv_row_in[i + index];
		end
	end
endmodule