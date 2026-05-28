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