module timer(clk, resetn, ack, div, tima_w, tima, tac, tma, interrupt, is_zero);
  input clk;
  input ack;
  input tima_w;
  input resetn;
  input [7:0] tac;
  input [7:0] tma;
  output reg [7:0] tima;
  output reg [7:0] div;
  output interrupt;
  output is_zero;

  reg[9:0] int_cnt = 0;
  reg interrupt;
  reg is_zero;

  always @(posedge clk) begin
    if (~resetn | tima_w) begin is_zero <= 0; interrupt <= 0; div <= 0; tima <= 0; int_cnt <= 0; end
    if (int_cnt[7:0] == 8'hff) div <= div + 1; // 1/256 of clk: 16384
    if ((tac[2:0] == 3'b100 && int_cnt[7:0] == 8'b11111111) || // 4096Hz
        (tac[2:0] == 3'b111 && int_cnt[5:0] == 6'b111111) || // 16kHz
        (tac[2:0] == 3'b110 && int_cnt[3:0] == 4'b1111) || // 64kHz
        (tac[2:0] == 3'b101 && int_cnt[1:0] == 4'b11)) // 256kHz
    begin
      if (tima == 8'hff) begin tima <= tma; interrupt <= ~ack; is_zero <= 1; end
      else tima <= tima + 1;
    end

    int_cnt <= int_cnt + 1;
    if (ack) interrupt <= 1'b0;
  end

endmodule
