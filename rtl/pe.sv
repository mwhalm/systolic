module pe #(
	parameter IA_WIDTH = 8,
	parameter W_WIDTH = 8,
	parameter OA_WIDTH = 24
)(
	input logic clk,
	input logic rst,
	input logic en_top,
	input logic en_left,
	input logic load,
	input logic signed [IA_WIDTH - 1 : 0] stream_in,
	input logic signed [W_WIDTH - 1 : 0] load_in,
	input logic signed [OA_WIDTH - 1 : 0] pe_in,

	output logic en_right,
	output logic en_bot,
	output logic signed [IA_WIDTH - 1 : 0] stream_out,
	output logic signed [OA_WIDTH - 1 : 0] pe_out
);

logic signed [W_WIDTH - 1 : 0] static_val;
logic en;

assign en = en_top | en_left;

always_ff @(posedge clk) begin
	if (!rst) begin
		stream_out <= '0;
		pe_out <= '0;
	end else begin
		en_right <= en;
		en_bot <= en;
		
		if (load)
			static_val <= load_in;
		
		if (en) begin
			stream_out <= stream_in;
			pe_out <= pe_in + (stream_in * static_val);
		end
	end
end
endmodule
