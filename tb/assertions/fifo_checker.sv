module fifo_checker #(parameter int DEPTH=16, parameter int PTR_W=$clog2(DEPTH))(
 input logic clk,rst_n,wr_en,rd_en,full,empty,input logic[PTR_W:0] count);
 logic [PTR_W:0] prev_count; logic prev_valid, prev_blocked_write, prev_blocked_read;
 always @(posedge clk or negedge rst_n) begin
   if(!rst_n) begin prev_count<='0; prev_valid<=0; prev_blocked_write<=0; prev_blocked_read<=0; end
   else begin
     if(prev_valid && prev_blocked_write && count!==prev_count) $error("FIFO overflow protection: count changed after blocked write");
     if(prev_valid && prev_blocked_read && count!==prev_count) $error("FIFO underflow protection: count changed after blocked read");
     if(count>DEPTH) $error("FIFO count out of range: %0d",count);
     prev_count<=count; prev_valid<=1;
     prev_blocked_write<=full && wr_en && !rd_en;
     prev_blocked_read<=empty && rd_en && !wr_en;
   end
 end
endmodule
