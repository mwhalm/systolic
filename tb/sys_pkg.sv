package sys_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    parameter int M_SIZE = `M_SIZE;
    parameter int K_SIZE = `K_SIZE;
    parameter int N_SIZE = `N_SIZE;
    parameter int N = `TILE_SIZE;
    parameter int IA_WIDTH  = 8;
    parameter int W_WIDTH   = 8;
    parameter int OA_WIDTH = 2 * IA_WIDTH + N;
    parameter int CONV_IA_ROW_SIZE = 3;
    parameter int FILTER_SIZE = 2;
	parameter int H = 3;
    parameter int W = 3;
    parameter int R = 2;
    parameter int S = 2;
    parameter int P = H - R + 1;
    parameter int Q = W - S + 1;
    parameter int X = R * S;      
    parameter int Z = P * Q;

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