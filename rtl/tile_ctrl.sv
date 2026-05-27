module tile_ctrl #(
    parameter TILE_SIZE,
    parameter M_TILES,
    parameter K_TILES,
    parameter N_TILES,
    parameter M_WIDTH,
    parameter K_WIDTH,
    parameter N_WIDTH
)(
    input  logic clk,
    input  logic rst,
    input  logic start,

    input  logic sys_done,

    output logic load_tile,
    output logic sys_start,
    output logic accumulate,
    output logic done,

    output logic [M_WIDTH - 1: 0] tile_i,
    output logic [N_WIDTH - 1: 0] tile_j,
    output logic [K_WIDTH - 1: 0] tile_k
);

    typedef enum logic [2 : 0] {
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
        if(!rst) begin
            state <= IDLE;
            tile_i <= 0;
            tile_j <= 0;
            tile_k <= 0;
            done <= '0;
            load_tile <= '0;
            sys_start <= '0;
            accumulate <= '0;
        end
        else begin
            load_tile <= 0;
            sys_start <= 0;
            accumulate <= 0;
            done <= 0;

            case(state)
                IDLE: begin
                    if(start) begin
                        tile_i <= '0;
                        tile_j <= '0;
                        tile_k <= '0;
                        state <= LOAD;
                    end
                end
                LOAD: begin
                    load_tile <= 1'b1;
                    state <= START;
                end
                START: begin
                    sys_start <= 1'b1;
                    state <= WAIT;
                end
                WAIT: begin
                    if(sys_done) begin
                        state <= ACCUM;
                    end
                end
                ACCUM: begin
                    accumulate <= 1'b1;
                    state <= NEXT_TILE;
                end
                NEXT_TILE: begin
                    if(tile_k < K_TILES - 1) begin
                        tile_k <= tile_k + 1'b1;
                        state <= LOAD;
                    end
                    else begin
                        tile_k <= 0;

                        // column tile
                        if(tile_j < N_TILES - 1) begin
                            tile_j <= tile_j + 1'b1;
                            state <= LOAD;
                        end
                        else begin
                            tile_j <= 0;

                            // row tile
                            if(tile_i < M_TILES - 1) begin
                                tile_i <= tile_i + 1'b1;
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