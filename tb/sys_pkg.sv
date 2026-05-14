package sys_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    parameter int N         = 8;
    parameter int IA_WIDTH  = 8;
    parameter int W_WIDTH   = 8;
    parameter int OA_WIDTH = 2 * IA_WIDTH + N;
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