module tile_ctrl #(
    parameter TILE_SIZE,
    parameter M_TILES,
    parameter K_TILES,
    parameter N_TILES,
    parameter CONV_M_TILES
)(
    input logic clk,
    input logic rst,
    input logic start,
    input logic sys_done,
    input logic [1 : 0] method,
    
    output logic load_tile,
    output logic sys_start,
    output logic accumulate,
    output logic done,
    output logic idle,
    output logic [7 : 0] tile_i,
    output logic [7 : 0] tile_j,
    output logic [7 : 0] tile_k
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
    logic row_stationary;
    logic [1 : 0] active_method;
    logic [7 : 0] active_m_tiles, active_n_tiles;

    assign idle = (state == IDLE); 
    assign row_stationary = (active_method == 2'b11);
    assign active_m_tiles = (active_method == 2'b11) ? CONV_M_TILES : M_TILES;

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
            active_method <= '0;
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
                        active_method <= method;
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
                    if(!row_stationary && tile_k < K_TILES - 1) begin
                        tile_k <= tile_k + 1'b1;
                        state <= LOAD;
                    end
                    else begin
                        tile_k <= 0;
                        if(!row_stationary && tile_j < N_TILES - 1) begin // column tile
                            tile_j <= tile_j + 1'b1;
                            state <= LOAD;
                        end
                        else begin
                            tile_j <= 0;
                            if(tile_i < active_m_tiles - 1) begin // row tile
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