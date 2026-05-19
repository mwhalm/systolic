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

logic signed [W_WIDTH - 1 : 0] static_val;
logic signed [OA_WIDTH - 1 : 0] acc;
logic en, ws_is;

assign en = en_top | en_left;
assign ws_is = (dataflow[1] == 1'b0);

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

		if(en) begin
			row_out <= row_in;
			if (ws_is) begin
				pe_out <= pe_in + row_in * static_val;
			end else begin
				col_out <= col_in;
				pe_out <= pe_out + row_in * col_in;
			end
		end
	end
end
endmodule
