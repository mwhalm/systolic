module tile_ctrl #(
    parameter MATRIX_SIZE = 16,
    parameter TILE_SIZE   = 8
)(
    input  logic clk,
    input  logic rst,
    input  logic start,

    input  logic systolic_done,

    output logic load_tile,
    output logic start_systolic,
    output logic accumulate,
    output logic done,

    output logic [$clog2(MATRIX_SIZE/TILE_SIZE)-1:0] tile_i,
    output logic [$clog2(MATRIX_SIZE/TILE_SIZE)-1:0] tile_j,
    output logic [$clog2(MATRIX_SIZE/TILE_SIZE)-1:0] tile_k
);

    localparam NUM_TILES = MATRIX_SIZE / TILE_SIZE;

    typedef enum logic [2:0] {
        IDLE,
        LOAD,
        START,
        WAIT,
        ACCUM,
        NEXT_TILE,
        FINISHED
    } state_t;

    state_t state;

    always_ff @(posedge clk) begin

        if(rst) begin
            state <= IDLE;
            tile_i <= 0;
            tile_j <= 0;
            tile_k <= 0;
            done <= 0;
            load_tile <= 0;
            start_systolic <= 0;
            accumulate <= 0;
        end
        else begin
            // Default
            load_tile <= 0;
            start_systolic <= 0;
            accumulate <= 0;
            done <= 0;

            case(state)

                IDLE: begin
                    if(start) begin
                        tile_i <= 0;
                        tile_j <= 0;
                        tile_k <= 0;
                        state <= LOAD;
                    end
                end

                LOAD: begin
                    load_tile <= 1;
                    state <= START;
                end

                START: begin
                    start_systolic <= 1;
                    state <= WAIT;
                end

                WAIT: begin
                    if(systolic_done) begin
                        state <= ACCUM;
                    end
                end

                ACCUM: begin
                    accumulate <= 1;
                    state <= NEXT_TILE;
                end

                NEXT_TILE: begin

                    // k dimension
                    if(tile_k < NUM_TILES - 1) begin
                        tile_k <= tile_k + 1;
                        state <= LOAD;
                    end
                    else begin
                        tile_k <= 0;

                        // column tile
                        if(tile_j < NUM_TILES - 1) begin
                            tile_j <= tile_j + 1;
                            state <= LOAD;
                        end
                        else begin
                            tile_j <= 0;

                            // row tile
                            if(tile_i < NUM_TILES - 1) begin
                                tile_i <= tile_i + 1;
                                state <= LOAD;
                            end
                            else begin
                                state <= FINISHED;
                            end
                        end
                    end
                end

		FINISHED: begin
                    done <= 1;
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule
