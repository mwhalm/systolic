module pe #(
	parameter IA_WIDTH = 8,
	parameter W_WIDTH = 8,
	parameter OA_WIDTH = 20
)(
	input logic clk,
	input logic rst,
	input logic en,
	input logic valid,
	input logic signed [IA_WIDTH - 1 : 0] ia_in,
	input logic signed [W_WIDTH - 1 : 0] w_in,
	input logic signed [OA_WIDTH - 1 : 0] oa_in,

	output logic signed [IA_WIDTH - 1 : 0] ia_out,
	output logic signed [W_WIDTH - 1 : 0] w_out,
	output logic signed [OA_WIDTH - 1 : 0] oa_out
);

logic [W_WIDTH - 1 : 0] weight;
logic [IA_WIDTH - 1 : 0] input_data;

always_ff @(posedge clk) begin
	if (rst) begin
		ia_out <= '0;
		w_out <= '0;
		oa_out <= '0;
	end else begin
		ia_out <= ia_in;
		w_out <= w_in;

		if (load_weight) begin
			weight <= w_in;
		end else begin
			weight <= weight;
		end
		
		if (en && valid) begin
			oa_out <= oa_in + (ia_in * weight);
		end else begin
			oa_out <= oa_in;
		end
	end
end
endmodule
