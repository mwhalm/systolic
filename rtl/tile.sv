module tile #(
    parameter M = 16,
    parameter K = 16,
    parameter N = 16,
    parameter TILE_SIZE = 8,
    parameter IA_WIDTH = 16,
    parameter W_WIDTH = 16,
    parameter OA_WIDTH,
    parameter FILTER_SIZE = 8,
    parameter H,
    parameter W,
    parameter P ,
    parameter Q
)(
    input logic clk,
    input logic rst,
    input logic start,
    input logic [1 : 0] method,
    input logic signed [IA_WIDTH - 1: 0] ia_in [0 : M - 1][0 : K - 1],
    input logic signed [W_WIDTH - 1: 0] w_in [0 : K - 1][0 : N - 1],
	input logic signed [IA_WIDTH - 1 : 0] conv_ia_in [0 : H - 1][0 : W - 1],
	input logic signed [W_WIDTH - 1 : 0] filter_in [0 : FILTER_SIZE - 1][0 : FILTER_SIZE - 1],

    output logic done,
    output logic signed [OA_WIDTH - 1 : 0] oa_out [0 : M - 1][0 : N - 1],
    output logic signed [OA_WIDTH - 1 : 0] conv_out [0 : P - 1][0 : Q - 1]
);
	localparam WS = 2'b00;
	localparam IS = 2'b01;
	localparam OS = 2'b10;
	localparam RS = 2'b11;

    localparam M_TILES = (M + TILE_SIZE - 1) / TILE_SIZE;
    localparam K_TILES = (K + TILE_SIZE - 1) / TILE_SIZE;
    localparam N_TILES = (N + TILE_SIZE - 1) / TILE_SIZE;
    localparam CONV_REAL_ROWS = TILE_SIZE + FILTER_SIZE - 1;
    localparam CONV_MAX_TILE_ROWS = 2 * TILE_SIZE - 1;
    localparam CONV_M_TILES = (P + TILE_SIZE - 1) / TILE_SIZE;

    logic signed [IA_WIDTH - 1 : 0] ia_tile [0 : TILE_SIZE - 1][0 : TILE_SIZE - 1];
    logic signed [W_WIDTH - 1 : 0] w_tile [0: TILE_SIZE - 1][0 : TILE_SIZE - 1];
    logic signed [OA_WIDTH - 1 : 0] oa_tile [0 : TILE_SIZE - 1][0 : TILE_SIZE - 1];
    logic signed [IA_WIDTH - 1 : 0] conv_ia_tile [0 : CONV_MAX_TILE_ROWS - 1][0 : W - 1];
    logic signed [W_WIDTH - 1 : 0] filter_tile [0 : TILE_SIZE - 1][0 : FILTER_SIZE - 1];
    logic signed [OA_WIDTH - 1 : 0] conv_out_tile [0 : TILE_SIZE - 1][0 : Q - 1];

    logic load_tile, sys_start, sys_done, accumulate, clear_acc, idle;
    logic [15 : 0] bound_r, bound_c;

    logic [7 : 0] tile_i;
    logic [7 : 0] tile_j;
    logic [7 : 0] tile_k;

    tile_ctrl #(
        .TILE_SIZE(TILE_SIZE),
        .M_TILES(M_TILES),
        .K_TILES(K_TILES),
        .N_TILES(N_TILES),
        .CONV_M_TILES(CONV_M_TILES)
    ) ctrl (
        .clk(clk),
        .rst(rst),
        .start(start),
        .method(method),

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
        .CONV_IA_ROW_SIZE(W),
        .CONV_OUT_SIZE(Q)
    ) systolic_array (
        .clk(clk),
        .rst(rst),
        .start(sys_start),
        .method(method),
        .ia_in(ia_tile),
        .w_in(w_tile),
        .conv_ia_in(conv_ia_tile),
        .filter_in(filter_tile),

        .done(sys_done),
        .oa_out(oa_tile),
        .conv_out(conv_out_tile)
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
            for (int i = 0; i < CONV_MAX_TILE_ROWS; i++) begin
                for (int j = 0; j < W; j++) begin
                    conv_ia_tile[i][j] <= '0;
                end
            end
            for(int i = 0; i < TILE_SIZE; i++) begin
                for(int j = 0; j < FILTER_SIZE; j++) begin
                    filter_tile[i][j] <= '0;
                end
            end
        end else if(load_tile) begin
            if(method != 2'b11) begin
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
            end else begin
                for(int i = 0; i < CONV_MAX_TILE_ROWS; i++) begin
                    for(int j = 0; j < W; j++) begin
                        if(i < CONV_REAL_ROWS && (tile_i * TILE_SIZE + i < H))
                            conv_ia_tile[i][j] <= conv_ia_in[tile_i * TILE_SIZE + i][j];
                        else
                            conv_ia_tile[i][j] <= '0;
                    end
                end
                for(int i = 0; i < TILE_SIZE; i++) begin
                    for(int j = 0; j < FILTER_SIZE; j++) begin
                        if(i < FILTER_SIZE)
                            filter_tile[i][j] <= filter_in[i][j];
                        else
                            filter_tile[i][j] <= '0;
                    end
                end
            end
        end
    end

    // Output Accumulation
    always_ff @(posedge clk) begin
        if(!rst || (idle && start)) begin
            for(int i = 0; i < M; i++) begin
                for(int j = 0; j < N; j++) begin
                    oa_out[i][j] <= '0;
                end
            end
            for(int i = 0; i < P; i++) begin
                for(int j = 0; j < Q; j++) begin
                    conv_out[i][j] <= '0;
                end
            end
        end else if(accumulate) begin
            if(method != RS) begin
                for(int i = 0; i < TILE_SIZE; i++) begin
                    for(int j = 0; j < TILE_SIZE; j++) begin
                        if(tile_i * TILE_SIZE + i < M && tile_j * TILE_SIZE + j < N) begin
                            oa_out[tile_i * TILE_SIZE + i][tile_j * TILE_SIZE + j] <= oa_out[tile_i * TILE_SIZE + i][tile_j * TILE_SIZE + j] + oa_tile[i][j];
                        end
                    end
                end
            end else begin
                for(int i = 0; i < TILE_SIZE; i++) begin
                    for(int j = 0; j < Q; j++) begin
                        if(tile_i * TILE_SIZE + i < P) begin
                            conv_out[tile_i * TILE_SIZE + i][j] <= conv_out_tile[i][j];
                        end
                    end
                end
            end
        end
    end
endmodule