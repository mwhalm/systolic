`timescale 1ns/1ps

module tb_msim_pe;

    localparam IA_WIDTH = 8;
    localparam W_WIDTH  = 8;
    localparam OA_WIDTH = 24;

    localparam CONV_IA_ROW_SIZE = 16;
    localparam FILTER_SIZE      = 8;

    localparam WS = 2'b00;
    localparam IS = 2'b01;
    localparam OS = 2'b10;
    localparam RS = 2'b11;

    logic clk;
    logic rst;

    logic en_top;
    logic en_left;
    logic load;
    logic [1:0] dataflow;

    logic signed [W_WIDTH-1:0] filter_row_in [0:FILTER_SIZE-1];

    logic signed [IA_WIDTH-1:0] conv_row_in [0:CONV_IA_ROW_SIZE-1];

    logic signed [IA_WIDTH-1:0] row_in;
    logic signed [W_WIDTH-1:0]  col_in;
    logic signed [IA_WIDTH-1:0] load_val;
    logic signed [OA_WIDTH-1:0] pe_in;

    logic en_right;
    logic en_bot;

    logic signed [IA_WIDTH-1:0] row_out;
    logic signed [W_WIDTH-1:0]  col_out;
    logic signed [OA_WIDTH-1:0] pe_out;

    int row_id;
    int col_id;

    pe #(
        .IA_WIDTH(IA_WIDTH),
        .W_WIDTH(W_WIDTH),
        .OA_WIDTH(OA_WIDTH),
        .CONV_IA_ROW_SIZE(CONV_IA_ROW_SIZE),
        .FILTER_SIZE(FILTER_SIZE)
    ) dut (
        .*
    );

    initial clk = 0;
    always #5 clk = ~clk;

    task automatic reset_dut();
    begin
        rst      = 0;
        load     = 0;
        en_top   = 0;
        en_left  = 0;
        row_in   = 0;
        col_in   = 0;
        load_val = 0;
        pe_in    = 0;

        repeat (3) @(posedge clk);

        rst = 1;
        @(posedge clk);
        #1;
    end
    endtask

    task automatic check_equal(
        input string name,
        input integer expected,
        input integer actual
    );
    begin
        if(actual !== expected)
            $error("%s FAILED exp=%0d act=%0d",name, expected, actual);
        else
            $display("%s PASS exp=%0d act=%0d",name, expected, actual);
    end
    endtask

    task automatic wait_cycle();
    begin
        @(posedge clk);
        #1;
    end
    endtask

    // WS Test
    task automatic test_ws();
    begin
        $display("\n--- WS TEST ---");

        dataflow = WS;

        load     = 1;
        load_val = 4;

        wait_cycle();

        load = 0;

        en_left = 1;
        row_in  = 3;
        pe_in   = 10;

        wait_cycle();

        check_equal(
            "WS",
            22,
            pe_out
        );

        check_equal(
            "WS row_out",
            3,
            row_out
        );

        en_left = 0;
    end
    endtask

    // IS Test
    task automatic test_is();
    begin
        $display("\n--- IS TEST ---");

        dataflow = IS;

        load     = 1;
        load_val = -2;

        wait_cycle();

        load = 0;

        en_top = 1;
        col_in = 7;
        pe_in  = 5;

        wait_cycle();

        check_equal(
            "IS",
            -9,
            pe_out
        );

        check_equal(
            "IS col_out",
            7,
            col_out
        );

        en_top = 0;
    end
    endtask

    // OS Test
    task automatic test_os();
    begin
        $display("\n--- OS TEST ---");

        dataflow = OS;

        load = 1;
        wait_cycle();
        load = 0;

        en_left = 1;

        // MAC #1
        row_in = 2;
        col_in = 3;

        wait_cycle();

        check_equal(
            "OS MAC1",
            6,
            pe_out
        );

        // MAC #2
        row_in = 4;
        col_in = 5;

        wait_cycle();

        check_equal(
            "OS MAC2",
            26,
            pe_out
        );

        en_left = 0;
    end
    endtask

    // RS Test
    task automatic test_rs();

        integer i;
        integer expected;

    begin

        $display("\n--- RS TEST ---");

        dataflow = RS;

        for(i=0;i<FILTER_SIZE;i++)
            filter_row_in[i] = i+1;

        for(i=0;i<CONV_IA_ROW_SIZE;i++)
            conv_row_in[i] = i+1;

        load = 1;
        wait_cycle();
        load = 0;

        // Window 0
        expected = 0;
        for(i=0;i<FILTER_SIZE;i++)
            expected += (i+1)*(i+1);

        en_left = 1;
        pe_in   = 0;

        wait_cycle();

        check_equal(
            "RS WINDOW0",
            expected,
            pe_out
        );

        // Window 1
        expected = 0;
        for(i=0;i<FILTER_SIZE;i++)
            expected += (i+1)*(i+2);

        wait_cycle();

        check_equal(
            "RS WINDOW1",
            expected,
            pe_out
        );

        en_left = 0;

    end
    endtask


    initial begin

        row_id = 0;
        col_id = 0;

        reset_dut();

        test_ws();
        test_is();
        test_os();
        test_rs();

        $display("\nALL TESTS COMPLETE");

        #20;
        $finish;
    end

endmodule