module dynamic_quantizer #(
    parameter N = 8,
    parameter IN_W = 16,
    parameter OUT_W = 8
)(
    input  logic signed [IN_W-1:0]  in_tile [0:N-1][0:N-1],
    output logic signed [OUT_W-1:0] out_tile [0:N-1][0:N-1],
    output logic [$clog2(IN_W):0] shift
);

    integer i, j;
    logic signed [IN_W-1:0] abs_val;
    logic signed [IN_W-1:0] max_val;

    always_comb begin
    	max_val = 0;
    	for (i = 0; i < N; i++) begin
		for (j = 0; j < N; j++) begin
			abs_val = in_tile[i][j][IN_W-1] ?-in_tile[i][j]:in_tile[i][j];
			if (abs_val > max_val) 
				max_val = abs_val;
		end
   	end

   	shift = 0;
   	for (int s = 0; s < (IN_W - OUT_W + 1); s++) begin
		if ((max_val >> s) > ((1 << (OUT_W-1)) - 1))
			shift = s + 1;
		if (shift > IN_W-1)
			shift = IN_W-1;
   	end
   
   	for (i = 0; i < N; i++) begin
		for (j = 0; j < N; j++) begin
			if(shift == 0) begin
				out_tile[i][j] = in_tile[i][j];
			end else begin
				out_tile[i][j] = (in_tile[i][j] + (1 << (shift-1))) >>> shift;
			end
		end
	end
    end
endmodule
