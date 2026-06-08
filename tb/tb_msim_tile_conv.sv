module tb_tile;

    parameter M = 16;
    parameter K = 16;
    parameter N = 16;
    parameter TILE_SIZE = 8;
    parameter CONV_IA_ROW_SIZE = 16;
    parameter FILTER_SIZE = 8;
    parameter CONV_OUT_SIZE = CONV_IA_ROW_SIZE - FILTER_SIZE + 1;

    logic clk;
    logic rst;
    logic start;
    logic [1:0] method;

    logic signed [15:0] ia_in [0:M-1][0:K-1];
    logic signed [15:0] w_in  [0:K-1][0:N-1];
    logic signed [15 : 0] conv_ia_in [0 : CONV_IA_ROW_SIZE - 1][0 : CONV_IA_ROW_SIZE - 1];
    logic signed [15: 0] filter_in [0 : 7][0 : 7];
    logic done;

    logic signed [23:0] oa_out [0:M-1][0:N-1];
    logic signed [23:0] conv_out [0 : CONV_OUT_SIZE - 1][0 : CONV_OUT_SIZE - 1];

    logic [2:0] state_debug;


    // DUT
    tile #(
        .M(M),
        .K(K),
        .N(N),
        .TILE_SIZE(TILE_SIZE)
    ) dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .method(2'b11),
        .ia_in(ia_in),
        .w_in(w_in),
		  .conv_ia_in(conv_ia_in),
		  .filter_in(filter_in),
        .done(done),
        .oa_out(oa_out),
		  .conv_out(conv_out),
		  .state_debug(state_debug)
    );
	 
	 
logic signed [15:0] golden [0:M-1][0:N-1];
logic signed [23:0] golden_conv [0 : CONV_OUT_SIZE - 1][0 : CONV_OUT_SIZE - 1];
initial clk = 0;
integer f_out;
integer errors;

always #5 clk = ~clk;

initial begin
    // Apply reset
    rst   = 0;
    start = 0;
	 
    //Initilize
    for (int i = 0; i < CONV_IA_ROW_SIZE; i++) begin
    	for (int j = 0; j < CONV_IA_ROW_SIZE; j++) begin
        	conv_ia_in[i][j] = i + j; 
        end
    end

    for (int i = 0; i < FILTER_SIZE; i++) begin
        for (int j = 0; j < FILTER_SIZE; j++) begin
                filter_in[i][j] = 1;
        end
    end
        
    // Zero out unused arrays
    for(int i=0; i<M; i++) for(int j=0; j<K; j++) ia_in[i][j] = 0;
    for(int i=0; i<K; i++) for(int j=0; j<N; j++) w_in[i][j] = 0;
		  
    //Golden
    for (int out_y = 0; out_y < CONV_OUT_SIZE; out_y++) begin
        for (int out_x = 0; out_x < CONV_OUT_SIZE; out_x++) begin
        	golden_conv[out_y][out_x] = 0;
                
          	// 2D Sliding Window
                for (int fy = 0; fy < FILTER_SIZE; fy++) begin
                    for (int fx = 0; fx < FILTER_SIZE; fx++) begin
                        golden_conv[out_y][out_x] += conv_ia_in[out_y + fy][out_x + fx] * filter_in[fy][fx];
                    end
                end
         end
    end
    $display("GOLDEN [0][0]: %0d", golden_conv[0][0]);
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // LAUNCH TEST
    repeat (5) @(posedge clk);

    // Release reset
    rst = 1;

    repeat (2) @(posedge clk);

    // Launch exactly one transaction
    start = 1;
    @(posedge clk);
    start = 0;

    $display("START issued @ %0t", $time);
	 
    //SCOREBOARD
    wait(done == 1);
    @(posedge clk);
    $display("DONE reached @ %0t. Writing CSV...", $time);
    f_out = $fopen("sim_out.csv", "w");
    $fwrite(f_out, "i,j,value\n");
    errors = 0;
    for (int i = 0; i < CONV_OUT_SIZE; i++) begin
    	for (int j = 0; j < CONV_OUT_SIZE; j++) begin
        	$fwrite(f_out,"%0d,%0d,%0d\n", i, j, conv_out[i][j]);
        end
    end
    $fclose(f_out);
    // Check the 9x9 conv_out against golden_conv
    for (int i = 0; i < CONV_OUT_SIZE; i++) begin
    	for (int j = 0; j < CONV_OUT_SIZE; j++) begin
        	if (conv_out[i][j] !== golden_conv[i][j]) begin
                	$display("MISMATCH [%0d][%0d] expected=%0d actual=%0d", i, j, golden_conv[i][j], conv_out[i][j]);
                	errors++;
                end
        end
    end
    if(errors == 0)
    	$display("SCOREBOARD PASS");
    else
	$display("SCOREBOARD FAIL: %0d errors", errors);
    repeat (5) @(posedge clk);
    $finish;
end
endmodule