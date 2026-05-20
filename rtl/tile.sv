module tile #(
    parameter MATRIX_SIZE = 16,
    parameter N = 8,
    parameter IA_WIDTH = 8,
    parameter W_WIDTH = 8,
    parameter OA_WIDTH = 24
)(
    input logic clk,
    input logic rst,
    input logic start,

    output logic done
);
    logic signed [IA_WIDTH-1:0] A [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1];
    logic signed [W_WIDTH-1:0] B [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1];
    logic signed [OA_WIDTH-1:0] C [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1];

    // Tile buffers
    logic signed [IA_WIDTH-1:0] ia_tile [0:N-1][0:N-1];
    logic signed [W_WIDTH-1:0] w_tile [0:N-1][0:N-1];
    logic signed [OA_WIDTH-1:0] oa_tile [0:N-1][0:N-1];

    logic load_tile;
    logic start_systolic;
    logic accumulate;

    logic systolic_done;

    logic [$clog2(MATRIX_SIZE/N)-1:0] tile_i;
    logic [$clog2(MATRIX_SIZE/N)-1:0] tile_j;
    logic [$clog2(MATRIX_SIZE/N)-1:0] tile_k;

    tile_ctrl #(
        .MATRIX_SIZE(MATRIX_SIZE),
        .TILE_SIZE(N)
    ) ctrl (
        .clk(clk),
        .rst(rst),
        .start(start),

        .systolic_done(systolic_done),

        .load_tile(load_tile),
        .start_systolic(start_systolic),
        .accumulate(accumulate),
        .done(done),

        .tile_i(tile_i),
        .tile_j(tile_j),
        .tile_k(tile_k)
    );

    systolic #(
        .N(N),
        .IA_WIDTH(IA_WIDTH),
        .W_WIDTH(W_WIDTH),
        .OA_WIDTH(OA_WIDTH)
    ) systolic_uut (
        .clk(clk),
        .rst(rst),
        .start(start_systolic),

        .method(2'b01), // Input Stationary

        .ia_in(ia_tile),
        .w_in(w_tile),

        .done(systolic_done),
        .oa_out(oa_tile)
    );

    // Tile Extraction
    always_ff @(posedge clk) begin
        if(load_tile) begin
            for(int r = 0; r < N; r++) begin
                for(int c = 0; c < N; c++) begin
                    ia_tile[r][c] <= A[tile_i*N + r][tile_k*N + c];
                    w_tile[r][c] <= B[tile_k*N + r][tile_j*N + c];
                end
            end
        end
    end

    // Output Accumulation
    always_ff @(posedge clk) begin
        if(accumulate) begin
            for(int r = 0; r < N; r++) begin
                for(int c = 0; c < N; c++) begin
                    C[tile_i*N + r][tile_j*N + c] <= C[tile_i*N + r][tile_j*N + c] + oa_tile[r][c];
                end
            end
        end
    end
endmodule
