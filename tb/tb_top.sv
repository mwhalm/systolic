module tb_top;
    import uvm_pkg::*;
    import sys_pkg::*;

    logic clk;

    always #5 clk = ~clk;

    systolic_if #(
        .M_SIZE(M_SIZE),
        .K_SIZE(K_SIZE),
        .N_SIZE(N_SIZE),
        .IA_WIDTH(IA_WIDTH),
        .W_WIDTH(W_WIDTH),
        .OA_WIDTH(OA_WIDTH),
        .FILTER_SIZE(FILTER_SIZE),
        .H(H),
        .W(W),
        .P(P),
        .Q(Q)
    ) sif (
        .clk(clk)
    );

    tile #(
        .M(M_SIZE),
        .K(K_SIZE),
        .N(N_SIZE),
        .TILE_SIZE(N),
        .IA_WIDTH(IA_WIDTH),
        .W_WIDTH(W_WIDTH),
        .OA_WIDTH(OA_WIDTH),
        .FILTER_SIZE(FILTER_SIZE),
        .H(H),
        .W(W),
        .P(P),
        .Q(Q)
    ) dut (
        .clk(clk),
        .rst(sif.rst),
        .start(sif.start),
        .method(sif.method),
        .ia_in(sif.ia_in),
        .w_in(sif.w_in),
        .conv_ia_in(sif.conv_ia_in),
        .filter_in(sif.filter_in),
        .done(sif.done),
        .oa_out(sif.oa_out),
        .conv_out(sif.conv_out)
    );

    initial begin
        clk = 0;
        $fsdbDumpfile("sys.fsdb");
        $fsdbDumpvars(0, tb_top);
        $fsdbDumpMDA(0, tb_top.dut);
        uvm_config_db#(virtual systolic_if #(M_SIZE, K_SIZE, N_SIZE, IA_WIDTH, W_WIDTH, 
            OA_WIDTH, FILTER_SIZE, H, W, P, Q).drv)::set(
            null, "uvm_test_top.env.agent.driver", "vif", sif.drv);
        uvm_config_db#(virtual systolic_if #(M_SIZE, K_SIZE, N_SIZE, IA_WIDTH, W_WIDTH, 
            OA_WIDTH, FILTER_SIZE, H, W, P, Q).mon)::set(
            null, "uvm_test_top.env.agent.monitor", "vif", sif.mon);
        run_test("sys_test");
    end
endmodule