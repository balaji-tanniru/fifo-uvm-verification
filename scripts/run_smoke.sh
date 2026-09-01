#!/usr/bin/env bash
set -euo pipefail
mkdir -p sim_build proof
iverilog -g2012 -o sim_build/fifo_sim rtl/sync_fifo.sv tb/smoke/fifo_tb.sv
vvp sim_build/fifo_sim | tee proof/fifo_test.log
grep -q FIFO_TEST_PASS proof/fifo_test.log
