module framebuffer #(
  parameter W=256, // width
  parameter H=256, // height
  parameter B=8, // bits/pix
  parameter D="" // initial data
)(
  input wire clk_in,
  input wire[15:0] addr_in,
  input wire[(B-1):0] data_in,
  input wire we,
  input wire clk_out,
  input wire[15:0] addr_out,
  output reg[(B-1):0] data_out
);
  reg[(B-1):0] mem[(W*H-1):0];

  initial
  begin $readmemh(D, mem); end

  always @(posedge clk_in)
  begin
    if (we) mem[addr_in] <= data_in;
  end

  always @(posedge clk_out)
  begin
    data_out <= mem[addr_out];
  end

endmodule
