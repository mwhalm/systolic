module quantize #(
    parameter ROWS,
    parameter COLS,
    parameter K,
    parameter IN_WIDTH,
    parameter OUT_WIDTH
)(
    input  logic clk,
    input  logic rst,
    input  logic start,
    input  logic signed [IN_WIDTH - 1 : 0] oa_in [0 : ROWS - 1][0 : COLS - 1],

    output logic done,
    output logic signed [OUT_WIDTH - 1 : 0] oa_quant [0 : ROWS - 1][0 : COLS - 1]
);

    localparam logic signed [OUT_WIDTH - 1 : 0] MAX = (1 <<< (OUT_WIDTH - 1)) - 1;
    localparam logic signed [OUT_WIDTH - 1 : 0] MIN = -(1 <<< (OUT_WIDTH - 1));

    typedef enum logic [2:0] {
        IDLE,
        FIND_MAX,
        CALC_SHIFT,
        QUANTIZE,
        DONE
    } state_t;

    state_t state;
    logic signed [IN_WIDTH : 0] quantized [0 : COLS - 1];
    logic [7 : 0] row, col, shift;
    logic [IN_WIDTH : 0] max_val, row_max, abs;

    always_comb begin
        row_max = '0;
        for(int i = 0; i < COLS; i++) begin
            if(oa_in[row][i] < 0)
                abs = -oa_in[row][i];
            else
                abs = oa_in[row][i];
            if(abs > row_max)
                row_max = abs;
        end
    end

    always_comb begin
        for(int i = 0; i < COLS; i++) begin
            quantized[i] = oa_in[row][i] >>> shift;
        end
    end

    always_ff @(posedge clk) begin
        if (!rst) begin
            state <= IDLE;
            row <= '0;
            done <= '0;
            max_val <= '0;
            shift <= '0;
            for (int i = 0; i < ROWS; i++) begin
                for (int j = 0; j < COLS; j++) begin
                    oa_quant[i][j] <= '0;
                end
            end
        end else begin
            done <= '0;
            case(state)
                IDLE : begin
                    row <= '0;
                    shift <= '0;
                    max_val <= '0;
                    if (start) begin
                        state <= FIND_MAX;
                    end
                end
                FIND_MAX : begin
                    if(row == ROWS - 1) begin
                        if(row_max > max_val)
                            max_val <= row_max;
                        row <= '0;
                        state <= CALC_SHIFT;
                    end else begin
                        if(row_max > max_val)
                            max_val <= row_max;
                        row <= row + 1'b1;
                    end
                end
                CALC_SHIFT : begin
                    if(max_val > MAX) begin
                        max_val <= max_val >> 1;
                        shift <= shift + 1'b1;
                    end else begin
                        shift <= shift - 1'b1;
                        state <= QUANTIZE;
                    end
                end
                QUANTIZE : begin
                    for (int i = 0; i < COLS; i++) begin
                        if (quantized[i] > MAX)
                            oa_quant[row][i] <= {1'b0, {(OUT_WIDTH - 1){1'b1}}};
                        else if (quantized[i] < MIN)
                            oa_quant[row][i] <= {1'b1, {(OUT_WIDTH - 1){1'b0}}};
                        else
                            oa_quant[row][i] <= quantized[i][OUT_WIDTH - 1 : 0];
                    end
                    if(row == ROWS - 1) begin
                        row <= '0;
                        state <= DONE;
                    end else begin
                        row <= row + 1'b1;
                    end
                end
                DONE : begin
                    done <= 1'b1;
                    state <= IDLE;
                end
                default : begin
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule