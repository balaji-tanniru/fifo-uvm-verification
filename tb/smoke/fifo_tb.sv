`timescale 1ns/1ps
module fifo_tb;
  localparam int WIDTH = 8;
  localparam int DEPTH = 16;
  logic clk = 0, rst_n = 0, wr_en = 0, rd_en = 0;
  logic [WIDTH-1:0] data_in = 0, data_out;
  logic full, empty;
  logic [$clog2(DEPTH):0] count;
  logic [WIDTH-1:0] expected [0:DEPTH-1];
  integer head = 0, tail = 0, model_count = 0;
  integer checks = 0, errors = 0, seed = 32'h51F0_2026;

  sync_fifo #(.WIDTH(WIDTH), .DEPTH(DEPTH)) dut (.*);
  always #5 clk = ~clk;

  task automatic drive(input bit w, input bit r, input logic [WIDTH-1:0] d);
    bit accepted_w, accepted_r;
    logic [WIDTH-1:0] exp;
    begin
      @(negedge clk);
      accepted_w = w && (model_count < DEPTH);
      accepted_r = r && (model_count > 0);
      if (accepted_r) exp = expected[head];
      wr_en = w; rd_en = r; data_in = d;
      @(posedge clk); #1;
      if (accepted_r) begin
        checks = checks + 1;
        if (data_out !== exp) begin
          $display("ERROR read expected=%0h actual=%0h", exp, data_out);
          errors = errors + 1;
        end
        head = (head + 1) % DEPTH;
      end
      if (accepted_w) begin
        expected[tail] = d;
        tail = (tail + 1) % DEPTH;
      end
      case ({accepted_w, accepted_r})
        2'b10: model_count = model_count + 1;
        2'b01: model_count = model_count - 1;
      endcase
      checks = checks + 1;
      if (count !== model_count || empty !== (model_count == 0) || full !== (model_count == DEPTH)) begin
        $display("ERROR flags/count model=%0d dut=%0d empty=%0b full=%0b", model_count, count, empty, full);
        errors = errors + 1;
      end
    end
  endtask

  initial begin
    $dumpfile("proof/fifo_wave.vcd");
    $dumpvars(0, fifo_tb);
    repeat (3) @(posedge clk);
    rst_n = 1;
    repeat (DEPTH) drive(1, 0, $random(seed));
    drive(1, 0, 8'hEE); // overflow attempt
    repeat (4) drive(1, 1, $random(seed));
    repeat (DEPTH) drive(0, 1, '0);
    drive(0, 1, '0); // underflow attempt
    repeat (40) drive($random(seed), $random(seed), $random(seed));
    while (model_count > 0) drive(0, 1, '0);
    if (errors == 0) $display("FIFO_TEST_PASS checks=%0d", checks);
    else begin $display("FIFO_TEST_FAIL errors=%0d", errors); $fatal(1); end
    $finish;
  end
endmodule
