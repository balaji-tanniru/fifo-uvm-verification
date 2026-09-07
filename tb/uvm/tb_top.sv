`timescale 1ns/1ps
module tb_top;
  import uvm_pkg::*; import fifo_pkg::*;
  localparam int DEPTH=16;
  logic clk=0; always #5 clk=~clk;
  fifo_if #(.WIDTH(8),.DEPTH(16)) vif(clk);
  sync_fifo #(.WIDTH(8),.DEPTH(16)) dut(
    .clk(clk),.rst_n(vif.rst_n),.wr_en(vif.wr_en),.rd_en(vif.rd_en),.data_in(vif.data_in),
    .data_out(vif.data_out),.full(vif.full),.empty(vif.empty),.count(vif.count));
  initial begin
    vif.rst_n=1; vif.wr_en=0; vif.rd_en=0; vif.data_in=0;
    uvm_config_db#(virtual fifo_if)::set(null,"*","vif",vif);
    uvm_config_db#(int)::set(null,"uvm_test_top.env.sb","depth",DEPTH);
    run_test("fifo_test");
  end
  initial begin #1ms; `uvm_fatal("TIMEOUT","FIFO UVM timeout") end
endmodule
