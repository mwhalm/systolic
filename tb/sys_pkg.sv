package sys_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    parameter int N = 8;    // systolic array size (N x N)
    parameter int M_SIZE = 40;    // A ~ M x K
    parameter int K_SIZE = 40;    // C ~ M x N
    parameter int N_SIZE = 40;    // B ~ K x N
    parameter int FILTER_SIZE = 2;    // square convolution filter size
    parameter int H = 40;    // height of convolution input matrix
    parameter int W = 3;    // width of convolution input matrix
    parameter int R = FILTER_SIZE;
    parameter int S = FILTER_SIZE;
    parameter int P = H - R + 1;    // output convolution height
    parameter int Q = W - S + 1;    // output convolution width
    parameter int IA_WIDTH = 8;
    parameter int W_WIDTH = 8;

    `ifdef CONV
        localparam int NUM_ADD = FILTER_SIZE * FILTER_SIZE;
    `else 
        localparam int NUM_ADD = K_SIZE;
    `endif

    parameter int OA_WIDTH = IA_WIDTH + W_WIDTH + $clog2(NUM_ADD) + 1;


    typedef enum logic {
        OP_MM   = 1'b0,
        OP_CONV = 1'b1
    } sys_op;

    `include "sys_item.sv"
    `include "sys_seq.sv"
    `include "sys_sequencer.sv"
    `include "sys_driver.sv"
    `include "sys_monitor.sv"
    `include "sys_agent.sv"
    `include "sys_scoreboard.sv"
    `include "sys_env.sv"
    `include "sys_test.sv"
endpackage
