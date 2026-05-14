module pe #(
	parameter IA_WIDTH = 8,
	parameter W_WIDTH = 8,
	parameter OA_WIDTH = 24
)(
	input logic clk,
	input logic rst,
	input logic en_top,
	input logic en_left,
	input logic load_weight,
	input logic signed [IA_WIDTH - 1 : 0] ia_in,
	input logic signed [W_WIDTH - 1 : 0] w_in,
	input logic signed [OA_WIDTH - 1 : 0] oa_in,

	output logic en_right,
	output logic en_bot,
	output logic signed [IA_WIDTH - 1 : 0] ia_out,
	output logic signed [OA_WIDTH - 1 : 0] oa_out
);

logic signed [W_WIDTH - 1 : 0] weight;
logic en;

assign en = en_top | en_left;

always_ff @(posedge clk) begin
	if (!rst) begin
		ia_out <= '0;
		oa_out <= '0;
	end else begin
		en_right <= en;
		en_bot <= en;
		
		if (load_weight)
			weight <= w_in;
		
		if (en) begin
			ia_out <= ia_in;
			oa_out <= oa_in + (ia_in * weight);
		end
	end
end
endmodule
