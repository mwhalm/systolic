module pe #(
	parameter IA_WIDTH = 8,
	parameter W_WIDTH = 8,
	parameter OA_WIDTH = 2 * IA_WIDTH + 8
)(
	input logic clk,
	input logic rst,
	input logic en_top,
	input logic en_left,
	input logic load,
	input logic [1 : 0] dataflow,
	input logic [2 : 0] filter_size,
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

	logic signed [W_WIDTH - 1 : 0] static_val;
	logic signed [OA_WIDTH - 1 : 0] acc;
	logic en, ws_is, os;

	assign en = en_top | en_left;
	assign ws_is = (dataflow[1] == 1'b0);
	assign os = (dataflow == 2'b10);

	always_ff @(posedge clk) begin
		if (!rst) begin
			row_out <= '0;
			col_out <= '0;
			pe_out <= '0;
			acc <= '0;
			en_right <= '0;
			en_bot <= '0;
		end else begin
			en_right <= en;
			en_bot <= en;
			
			if (load && ws_is)
				static_val <= load_val;
			else if (load && os)
				pe_out <= '0;

			if(en) begin
				row_out <= row_in;
				unique case(dataflow)
					WS, IS : pe_out <= pe_in + row_in * static_val;
					OS : begin
						col_out <= col_in;
						pe_out <= pe_out + row_in * col_in;
					end
					RS : begin

					end
				endcase
			end
		end
	end
endmodule
