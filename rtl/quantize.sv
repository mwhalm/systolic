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

    localparam logic signed [IN_WIDTH - 1 : 0] MAX = {1'b0, {(OUT_WIDTH - 1){1'b1}}};
    localparam logic signed [IN_WIDTH - 1 : 0] MIN = {1'b1, {(OUT_WIDTH - 1){1'b0}}};
    localparam logic signed [OUT_WIDTH - 1 : 0] Q_MAX = MAX;
    localparam logic signed [OUT_WIDTH - 1 : 0] Q_MIN = MIN; 

    localparam MAX_SHIFT  = IN_WIDTH - OUT_WIDTH;
    localparam BASE_SHIFT = 2 + $clog2(OUT_WIDTH);

    localparam RAW_SHIFT = BASE_SHIFT + $clog2(K);
    localparam OUT_SHIFT = (RAW_SHIFT > MAX_SHIFT) ? MAX_SHIFT : RAW_SHIFT;

    logic signed [IN_WIDTH - 1 : 0] quantized [0 : ROWS - 1][0 : COLS - 1];

    always_comb begin
        for(int i = 0; i < ROWS; i++) begin
            for(int j = 0; j < COLS; j++) begin
                quantized[i][j] = oa_in[i][j] >>> OUT_SHIFT;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (!rst) begin
            done <= 1'b0;
            for (int i = 0; i < ROWS; i++) begin
                for (int j = 0; j < COLS; j++) begin
                    oa_quant[i][j] <= '0;
                end
            end
        end else begin
            done <= 1'b0;
            if (start) begin
                for (int i = 0; i < ROWS; i++) begin
                    for (int j = 0; j < COLS; j++) begin
                        if (quantized[i][j] > Q_MAX)
                            oa_quant[i][j] <= {1'b0, {(OUT_WIDTH - 1){1'b1}}};
                        else if (quantized[i][j] < Q_MIN)
                            oa_quant[i][j] <= {1'b1, {(OUT_WIDTH - 1){1'b0}}};
                        else
                            oa_quant[i][j] <= quantized[i][j][OUT_WIDTH - 1 : 0];
                    end
                end
                done <= 1'b1;
            end
        end
    end
endmodule