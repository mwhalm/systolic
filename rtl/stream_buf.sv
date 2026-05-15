module stream_buf #(
	parameter N = 8,
	parameter WIDTH = 8
) (
	input clk,
	input rst,
	input en,
	input load,
	input logic signed [WIDTH - 1 : 0] in [0 : N - 1],

	output logic signed [WIDTH - 1 : 0] buf_out
);

logic signed [WIDTH - 1 : 0] mem [0 : N - 1];

always_ff @(posedge clk) begin
	if(!rst) begin
		for(int i = 0; i < N; i++) begin
			mem[i] <= '0;
		end
	end else begin
		if(load) begin
			for(int i = 0; i < N; i++) begin
				mem[i] <= in[i];
			end
		end
		if(en) begin
			buf_out <= mem[0];
			for(int i = 0; i < N - 1; i++) begin
				mem[i] <= mem[i + 1];
			end	
			mem[N - 1] <= '0;
		end
	end
end
endmodule