module sys_ctrl #(
	parameter N = 8,
	parameter CONV_OUT_SIZE
) (
	input clk,
	input rst,
	input start,
	input logic [1 : 0] method, 

	output load,
	output en,
	output done,
	output conv_buf_en,
	output conv_buf_clr,
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
	localparam CONV_COMPUTE_CYCLES = 2 * N + CONV_OUT_SIZE - 1;

	state_t state, next;
	mode df_next, df_reg; 

	logic [$clog2(2 * N) : 0] count, drain;

	assign load = (state == LOAD);
	assign en = (state == COMPUTE);
	assign done = (state == DONE);
	assign df = df_reg;
	assign conv_buf_en = (state == DRAIN) && (method == 2'b11);
	assign conv_buf_clr = (state == DONE);
	
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
				next = LOAD;
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
			end
			LOAD: begin
				next = COMPUTE;
			end 
			COMPUTE: begin
				if(method != 2'b11) begin
					if(count == COMPUTE_CYCLES)
						next = DRAIN;
				end else begin
					if(count == CONV_COMPUTE_CYCLES)
						next = DRAIN;
				end
			end
			DRAIN: begin
				if(method != 2'b11) begin
					if(drain == N)
						next = DONE;
				end else begin
					if(drain == CONV_OUT_SIZE - 1)
						next = DONE;
				end
			end
			DONE: begin
				next = IDLE;
			end
		endcase
	end
endmodule