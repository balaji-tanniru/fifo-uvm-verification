module sync_fifo #(
  parameter int WIDTH = 8,
  parameter int DEPTH = 16,
  localparam int PTR_W = $clog2(DEPTH)
) (
  input  logic             clk,
  input  logic             rst_n,
  input  logic             wr_en,
  input  logic             rd_en,
  input  logic [WIDTH-1:0] data_in,
  output logic [WIDTH-1:0] data_out,
  output logic             full,
  output logic             empty,
  output logic [PTR_W:0]   count
);
  logic [WIDTH-1:0] mem [0:DEPTH-1];
  logic [PTR_W-1:0] wr_ptr, rd_ptr;

  assign full  = (count == DEPTH);
  assign empty = (count == 0);

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr   <= '0;
      rd_ptr   <= '0;
      count    <= '0;
      data_out <= '0;
    end else begin
      if (wr_en && !full) begin
        mem[wr_ptr] <= data_in;
        wr_ptr <= (wr_ptr == DEPTH-1) ? '0 : wr_ptr + 1'b1;
      end
      if (rd_en && !empty) begin
        data_out <= mem[rd_ptr];
        rd_ptr <= (rd_ptr == DEPTH-1) ? '0 : rd_ptr + 1'b1;
      end
      case ({wr_en && !full, rd_en && !empty})
        2'b10: count <= count + 1'b1;
        2'b01: count <= count - 1'b1;
        default: count <= count;
      endcase
    end
  end
endmodule
