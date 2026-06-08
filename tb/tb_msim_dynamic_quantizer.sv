module tb_dynamic_quantizer;

    parameter N = 8;
    parameter IN_W = 16;
    parameter OUT_W = 8;

    logic signed [IN_W-1:0] in_tile [0:N-1][0:N-1];
    logic signed [OUT_W-1:0] out_tile [0:N-1][0:N-1];
    logic [$clog2(IN_W):0] shift;

    dynamic_quantizer #(
        .N(N),
        .IN_W(IN_W),
        .OUT_W(OUT_W)
    ) dut (
        .in_tile(in_tile),
        .out_tile(out_tile),
        .shift(shift)
    );

    initial begin

        // Pass-Through (Values safely inside 8-bit range)
        for (int i = 0; i < N; i++) begin
            for (int j = 0; j < N; j++) begin
                in_tile[i][j] = 50;
            end
        end
        in_tile[0][0] = 127;
        in_tile[7][7] = -128;
        #10;
        $display("Pass-Through (No Shift)");
        $display("  -> Shift      : %0d (Expected: 0)", shift);
        $display("  -> out[0][0]  : %0d (Expected: 127)", out_tile[0][0]);
        $display("  -> out[7][7]  : %0d (Expected: -128)", out_tile[7][7]);
        $display("  -> out[1][1]  : %0d (Expected: 50)", out_tile[1][1]);
        $display("--------------------------------------------------");

        // Extreme Bounds (16-bit limits)
        for (int i = 0; i < N; i++) begin
            for (int j = 0; j < N; j++) begin
                in_tile[i][j] = 0;
            end
        end
        in_tile[0][0] = 32767;  // Max 16-bit positive
        in_tile[1][1] = -32768; // Max 16-bit negative
        #10;
        $display("Maximum Extremes (16-bit limits)");
        // 32767 needs a shift of 8 to fit into 127. 
        $display("  -> Shift      : %0d (Expected: 8)", shift);
        $display("  -> out[0][0]  : %0d (Expected: 127 or 128 depending on rounding)", out_tile[0][0]);
        $display("  -> out[1][1]  : %0d (Expected: -128)", out_tile[1][1]);
        $display("--------------------------------------------------");

        // ---------------------------------------------------------
        // Mixed Scales & Rounding
        // A single large value dictates the scale for smaller values
        // ---------------------------------------------------------
        for (int i = 0; i < N; i++) begin
            for (int j = 0; j < N; j++) begin
                in_tile[i][j] = 15; // Small baseline
            end
        end
        in_tile[3][3] = 1000; // The outlier
        #10;
        $display("Mixed Scales (Outlier Crush)");
        // 1000 requires a right shift of 3 to become 125.
        // Therefore, 15 >> 3 = 1. With rounding: (15 + 4) >> 3 = 2.
        $display("  -> Shift      : %0d (Expected: 3)", shift);
        $display("  -> out[3][3]  : %0d (Expected: 125) [The Outlier]", out_tile[3][3]);
        $display("  -> out[0][0]  : %0d (Expected: 2)   [The Crushed Baseline]", out_tile[0][0]);
        $display("==================================================");
        $finish;
    end
endmodule

endmodule