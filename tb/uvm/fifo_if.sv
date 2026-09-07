interface fifo_if #(int WIDTH=8,int DEPTH=16)(input logic clk);
 logic rst_n,wr_en,rd_en; logic[WIDTH-1:0] data_in,data_out; logic full,empty; logic[$clog2(DEPTH):0] count;
 property no_overflow; @(posedge clk) disable iff(!rst_n) full&&wr_en&&!rd_en |=> $stable(count); endproperty
 property no_underflow; @(posedge clk) disable iff(!rst_n) empty&&rd_en&&!wr_en |=> $stable(count); endproperty
 property count_in_range; @(posedge clk) disable iff(!rst_n) count<=DEPTH; endproperty
 a_no_overflow:assert property(no_overflow); a_no_underflow:assert property(no_underflow); a_count_range:assert property(count_in_range);
endinterface
