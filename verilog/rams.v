module rams #(
  parameter D="",
  parameter A=15
)(clk, we, addr, di, do);

  input clk;
  input we;
  input [(A-1):0] addr;
  input [7:0] di;
  output [7:0] do;
  reg [7:0] mem [0:(2**A)-1];
  reg [7:0] do;

  initial begin
    $readmemh(D, mem);
  end

  always @(posedge clk) begin
    if (we) mem[addr] <= di;
    do <= mem[addr];
  end

endmodule
