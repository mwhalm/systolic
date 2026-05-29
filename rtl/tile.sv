module tile #(
    parameter M = 16,
    parameter K = 16,
    parameter N = 16,
    parameter TILE_SIZE = 8,
    parameter IA_WIDTH = 8,
    parameter W_WIDTH = 8,
    parameter OA_WIDTH = 24,
    parameter FILTER_SIZE = 8,
    parameter CONV_IA_ROW_SIZE = 16
)(
    input logic clk,
    input logic rst,
    input logic start,
    input logic [1 : 0] method,
    input logic signed [IA_WIDTH - 1: 0] ia_in [0 : M - 1][0 : K - 1],
    input logic signed [W_WIDTH - 1: 0] w_in [0 : K - 1][0 : N - 1],
	input logic signed [IA_WIDTH - 1 : 0] conv_ia_in [0 : CONV_IA_ROW_SIZE - 1][0 : CONV_IA_ROW_SIZE - 1],
	input logic signed [W_WIDTH - 1 : 0] filter_in [0 : FILTER_SIZE - 1][0 : FILTER_SIZE - 1],

    output logic done,
    output logic signed [OA_WIDTH - 1 : 0] oa_out [0 : M - 1][0 : N - 1]
);

    parameter M_TILES = (M + TILE_SIZE - 1) / TILE_SIZE;
    parameter K_TILES = (K + TILE_SIZE - 1) / TILE_SIZE;
    parameter N_TILES = (N + TILE_SIZE - 1) / TILE_SIZE;
    parameter M_WIDTH = (M_TILES <= 1) ? 1 : $clog2(M_TILES);
    parameter K_WIDTH = (K_TILES <= 1) ? 1 : $clog2(K_TILES);
    parameter N_WIDTH = (N_TILES <= 1) ? 1 : $clog2(N_TILES);

    logic signed [IA_WIDTH - 1 : 0] ia_tile [0 : TILE_SIZE - 1][0 : TILE_SIZE - 1];
    logic signed [W_WIDTH - 1 : 0] w_tile [0: TILE_SIZE - 1][0 : TILE_SIZE - 1];
    logic signed [OA_WIDTH - 1 : 0] oa_tile [0 : TILE_SIZE - 1][0 : TILE_SIZE - 1];

    logic load_tile, sys_start, sys_done, accumulate, clear_acc, idle;

    logic [M_WIDTH - 1: 0] tile_i;
    logic [N_WIDTH - 1: 0] tile_j;
    logic [K_WIDTH - 1: 0] tile_k;

    tile_ctrl #(
        .TILE_SIZE(TILE_SIZE),
        .M_TILES(M_TILES),
        .K_TILES(K_TILES),
        .N_TILES(N_TILES),
        .M_WIDTH(M_WIDTH),
        .K_WIDTH(K_WIDTH),
        .N_WIDTH(N_WIDTH)
    ) ctrl (
        .clk(clk),
        .rst(rst),
        .start(start),

        .sys_done(sys_done),
        .load_tile(load_tile),
        .sys_start(sys_start),
        .accumulate(accumulate),
        .done(done),
        .idle(idle),
        .tile_i(tile_i),
        .tile_j(tile_j),
        .tile_k(tile_k)
    );

    systolic #(
        .N(TILE_SIZE),
        .IA_WIDTH(IA_WIDTH),
        .W_WIDTH(W_WIDTH),
        .OA_WIDTH(OA_WIDTH),
        .FILTER_SIZE(FILTER_SIZE),
        .CONV_IA_ROW_SIZE(CONV_IA_ROW_SIZE)
    ) systolic_array (
        .clk(clk),
        .rst(rst),
        .start(sys_start),
        .method(method),
        .ia_in(ia_tile),
        .w_in(w_tile),
        .conv_ia_in(conv_ia_in),
        .filter_in(filter_in),

        .done(sys_done),
        .oa_out(oa_tile)
    );

    // Tile Extraction
    always_ff @(posedge clk) begin
        if(!rst) begin
            for(int i = 0; i < TILE_SIZE; i++) begin
                for(int j = 0; j < TILE_SIZE; j++) begin
                    ia_tile[i][j] <= '0;
                    w_tile[i][j] <= '0;
                end
            end      
        end else if(load_tile) begin
            for(int i = 0; i < TILE_SIZE; i++) begin
                for(int j = 0; j < TILE_SIZE; j++) begin
                    if(tile_i * TILE_SIZE + i < M && tile_k * TILE_SIZE + j < K)
                        ia_tile[i][j] <= ia_in[tile_i * TILE_SIZE + i][tile_k * TILE_SIZE + j];
                    else
                        ia_tile[i][j] <= '0;

                    if(tile_k * TILE_SIZE + i < K && tile_j * TILE_SIZE + j < N)
                        w_tile[i][j] <= w_in[tile_k * TILE_SIZE + i][tile_j * TILE_SIZE + j];
                    else
                        w_tile[i][j] <= '0;
                end
            end
        end
    end

    // Output Accumulation
    always_ff @(posedge clk) begin
        if(!rst || idle) begin
            for(int i = 0; i < M; i++) begin
                for(int j = 0; j < N; j++) begin
                    oa_out[i][j] <= '0;
                end
            end      
        end else if(accumulate) begin
            for(int i = 0; i < TILE_SIZE; i++) begin
                for(int j = 0; j < TILE_SIZE; j++) begin
                    if(tile_i * TILE_SIZE + i < M && tile_j * TILE_SIZE + j < N) begin
                        oa_out[tile_i * TILE_SIZE + i][tile_j * TILE_SIZE + j] <= oa_out[tile_i * TILE_SIZE + i][tile_j * TILE_SIZE + j] + oa_tile[i][j];
                    end
                end
            end
        end
    end
endmodule