module sys_ctrl #(
	parameter N = 8
) (
	input clk,
	input rst,
	input start,

	output load,
	output en,
	output done
);
	typedef enum logic [1:0] {
		IDLE,
		LOAD,
		COMPUTE,
		DONE
	} state_t;
	
	localparam COMPUTE_CYCLES = 3 * N - 1;

	state_t state, next;

	logic [$clog2(2 * N): 0] count;

	assign load = (state == LOAD);
	assign en = (state == COMPUTE);
	assign done = (state == DONE);

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

		case(state)
			IDLE: begin
				if(start)
					next = LOAD;
			end
			LOAD: begin
				next = COMPUTE;
			end 
			COMPUTE: begin
				if(count == COMPUTE_CYCLES)
					next = DONE;
			end
			DONE: begin
				if(start)
					next = IDLE;
			end
		endcase
	end
endmodule