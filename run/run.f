-sverilog
-debug_access+all
-kdb
-timescale=1ns/1ns

+incdir+../tb

../tb/sys_pkg.sv
../rtl/systolic_if.sv
../rtl/stream_buf.sv
../rtl/conv_buf.sv
../rtl/pe.sv
../rtl/sys_ctrl.sv
../rtl/systolic.sv
../rtl/quantize.sv
../rtl/tile_ctrl.sv
../rtl/tile.sv
../tb/tb_top.sv
