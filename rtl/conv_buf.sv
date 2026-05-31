module conv_buf #(
	parameter CONV_OUT_SIZE = 4,
	parameter WIDTH = 8
) (
	input clk,
	input rst,
	input en,
	input load,
	input clr,
	input logic signed [WIDTH - 1 : 0] in,

	output logic signed [WIDTH - 1 : 0] buf_out
);

logic signed [WIDTH - 1 : 0] mem [0 : CONV_OUT_SIZE - 1];
logic [7 : 0] index;

assign buf_out = mem[0];

always_ff @(posedge clk) begin
	if(!rst) begin
        index <= '0;
		for(int i = 0; i < CONV_OUT_SIZE; i++) begin
			mem[i] <= '0;
		end
	end else begin
		if(load) begin
			mem[index] <= in;
            index <= index + 1'b1;
		end else if (clr) begin
			index <= '0;
		end else if (en) begin
			for(int i = 0; i < CONV_OUT_SIZE - 1; i++) begin
				mem[i] <= mem[i + 1];
			end
			mem[CONV_OUT_SIZE - 1] <= '0;
		end
	end
end
endmodule