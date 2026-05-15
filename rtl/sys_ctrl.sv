module sys_ctrl #(
	parameter N = 8
) (
	input clk,
	input rst,
	input start,
	input logic [1 : 0] method, 

	output load,
	output en,
	output done,
	output logic [1 : 0] df
);
	typedef enum logic [2 : 0] {
		IDLE,
		CHOOSE,
		LOAD,
		COMPUTE,
		DRAIN,
		DONE
	} state_t;
	
	typedef enum logic [1 : 0] {
		WS = 2'b00,
		IS = 2'b01,
		OS = 2'b10,
		RS = 2'b11
	} mode;

	localparam COMPUTE_CYCLES = 3 * N - 1;

	state_t state, next;
	mode df_next, df_reg; 

	logic [$clog2(2 * N): 0] count, drain;

	assign load = (state == LOAD);
	assign en = (state == COMPUTE);
	assign done = (state == DONE);
	assign df = df_reg;
	
	always_ff @(posedge clk) begin
		if(!rst) begin
			state <= IDLE;
			count <= '0;
			drain <= '0;
			df_reg <= WS;
		end else begin
			state <= next;
			count <= (state == COMPUTE) ? count + 1'b1 : '0;
			drain <= (state == DRAIN) ? drain + 1'b1 : '0;
			df_reg <= df_next;
		end
	end

	always_comb begin
		next = state;
		df_next = df_reg;

		case(state)
			IDLE: begin
				if(start)
					next = CHOOSE;
			end
			CHOOSE: begin
				case (method)
					WS : begin
						df_next = WS;
					end
					IS : begin
						df_next = IS;
					end 
					OS : begin
						df_next = OS;
					end
					RS : begin
						df_next = RS;
					end
				endcase
				next = LOAD;
			end
			LOAD: begin
				next = COMPUTE;
			end 
			COMPUTE: begin
				if(count == COMPUTE_CYCLES)
					next = DRAIN;
			end
			DRAIN: begin
				if(drain == N)
					next = DONE;
			end
			DONE: begin
				next = IDLE;
			end
		endcase
	end
endmodule