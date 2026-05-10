module sys_ctrl #(
	parameter N = 8;
) (
	input clk,
	input rst,
	input start,

	output load,
	output idle
);
	typedef enum logic [1:0] {
		IDLE,
		LOAD,
		COMPUTE,
	} state_t;
	
	localparam COMPUTE_CYCLES = 2 * N - 1;

	state_t state, next;

	logic [$clog2(2 * N) - 1 : 0] count;

	always_ff @(posedge clk) begin
		if(!rst) begin
			state <= IDLE;
			count <= '0;
		end else begin
			state <= next;
			count <= (state == COMPUTE) ? count + 1'b1 : '0;
		end
	end

	always_comb begin
		next = state;
		idle = 1'b0;
		load_weight = 1'b0;

		case(state)
			IDLE: begin
				idle = 1'b1;
				if(start)
					next = LOAD_WEIGHT;
			end
			LOAD: begin
				load = 1'b1;
				next = COMPUTE;
			end 
			COMPUTE: begin
				if(count == COMPUTE_CYCLES)
					next = IDLE;
			end
	end
endmodule