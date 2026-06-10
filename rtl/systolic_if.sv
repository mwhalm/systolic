interface systolic_if #(
	parameter M_SIZE,
    parameter K_SIZE,
    parameter N_SIZE,
	parameter IA_WIDTH = 16,
	parameter W_WIDTH = 16,
	parameter OA_WIDTH = 24,
    parameter FILTER_SIZE,
    parameter H,
    parameter W,
    parameter P = H - FILTER_SIZE + 1,
    parameter Q = W - FILTER_SIZE + 1
) (
	input logic clk
);
	logic rst;
	logic start;
    logic done;
    logic [1 : 0] method;
	logic signed [IA_WIDTH - 1 : 0] ia_in [0 : M_SIZE - 1][0 : K_SIZE - 1];
	logic signed [W_WIDTH - 1 : 0] w_in [0 : K_SIZE - 1][0 : N_SIZE - 1];
	logic signed [IA_WIDTH - 1 : 0] oa_out [0 : M_SIZE - 1][0 : N_SIZE - 1];
    logic signed [OA_WIDTH - 1 : 0] conv_out [0 : P - 1][0 : Q - 1];
    logic signed [IA_WIDTH - 1 : 0] conv_ia_in [0 : H - 1][0 : W - 1];
    logic signed [W_WIDTH - 1 : 0] filter_in [0 : FILTER_SIZE - 1][0 : FILTER_SIZE - 1];

    modport drv (
        input clk,
        input oa_out,
        input conv_out,
        input done,
        
        output method,
        output start,
        output rst,
        output ia_in,
        output w_in,
        output conv_ia_in,
        output filter_in
    );

    modport mon (
        input clk,
        input rst,
        input start,
        input ia_in,
        input w_in,
        input oa_out,
        input conv_out,
        input conv_ia_in,
        input filter_in,
        input done,
        input method
    );
endinterface