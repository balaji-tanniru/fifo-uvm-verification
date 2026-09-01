#!/usr/bin/env bash
set -euo pipefail
rm -rf work transcript vsim.wlf
vlib work
vlog -sv +incdir+tb/uvm rtl/sync_fifo.sv tb/uvm/fifo_if.sv tb/uvm/fifo_pkg.sv tb/uvm/tb_top.sv
vsim -c -coverage tb_top -do "log -r /*; vcd file proof/fifo_uvm_wave.vcd; vcd add -r /*; run -all; coverage report -details -output proof/fifo_coverage.txt; quit -f" | tee proof/fifo_uvm.log
