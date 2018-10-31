module lcd #(
  parameter hRez = 640,
  parameter hStartSync = 656,
  parameter hEndSync = 752,
  parameter hMaxCount = 800,
  parameter hSyncActive = 0,
  parameter vRez = 480,
  parameter vStartSync = 490,
  parameter vEndSync = 492,
  parameter vMaxCount = 525,
  parameter vSyncActive = 1,
  parameter initial_x = 20,
  parameter initial_y = 20
 )(
  input pixelClock,
  input wire[1:0] sw,
  input wire[3:0] btn,
  output reg[7:0] red,
  output reg[7:0] green,
  output reg[7:0] blue,
  output reg hSync,
  output reg vSync,
  output reg blank,

  output reg[15:0] va,
  input wire[15:0] ppu_addr,
  input wire[23:0] vd
);

  reg[11:0] x;
  reg[11:0] line;
  reg[8:0] off_x=initial_x;
  reg[8:0] off_y=initial_y;

  wire[11:0] px = x - off_x;
  wire[11:0] py = line - off_y;

  wire valid = (px) < 256 && (py) < 256;

  wire[23:0] fb_data = vd;

  reg[17:0] btn_cnt[3:0];

  always @(posedge pixelClock)
  begin
    hSync <= ~hSyncActive; vSync <= ~vSyncActive;

    if (x == hMaxCount-1) begin
      x <= 0;
      if (line == vMaxCount-1) begin
        line <= 0;
      end else begin
        line <= line + 1;
      end
    end else begin
      x <= x + 1;
    end

    if (x < hRez && line < vRez)
    begin
      if (valid) begin
        va <= {py[7:0], px[7:0]}+1;
        case (sw[1:0])
          2'b00 :
          begin
            // color test (256x256)
            red <= {px[5:0], px[5:4]}; green <= px[7:0]; blue <= py[7:0];
          end
          2'b11:
          begin
            red <= fb_data[7:0]; green <= fb_data[15:8]; blue <= fb_data[23:16];
          end
          2'b10:
          begin
            red <= (px[2:0] == 0) ? 8'hff : 0; green <= (py[2:0] == 0) ? 8'hff : 0;
          end
          2'b01:
          begin
            red <= (x[2:0] == 0) ? 8'hff : 0; green <= (line[2:0] == 0) ? 8'hff : 0;
          end
        default: ;
        endcase
        red[7] <= fb_data[7] ^ (ppu_addr == va);
      end else
      begin
        if ((x[6] ^ line[6]) == 1'b1) begin
          red <= 8'h40; green <= 8'h40; blue <= 8'h40;
        end else begin
          red <= 8'h20; green <= 8'h20; blue <= 8'h20;
        end
      end
      blank <= 1'b0;
    end else begin blank <= 1'b1; end

    if (x >= hStartSync && x < hEndSync) begin hSync <= hSyncActive; end
    if (line >= vStartSync && line < vEndSync) begin vSync <= vSyncActive; end
    btn_cnt[3] <= btn_cnt[3] + btn[3]; btn_cnt[2] <= btn_cnt[2] + btn[2];
    btn_cnt[1] <= btn_cnt[1] + btn[1]; btn_cnt[0] <= btn_cnt[0] + btn[0];
    if (btn_cnt[3] == 18'b11111111111111111) begin off_x <= off_x - 1; btn_cnt[3] <= 0; end
    if (btn_cnt[2] == 18'b11111111111111111) begin off_y <= off_y + 1; btn_cnt[2] <= 0; end
    if (btn_cnt[1] == 18'b11111111111111111) begin off_y <= off_y - 1; btn_cnt[1] <= 0; end
    if (btn_cnt[0] == 18'b11111111111111111) begin off_x <= off_x + 1; btn_cnt[0] <= 0; end
    if (off_x==hRez-256) off_x<=0;
    if (off_x==9'b111111111) off_x<=hRez-257;
    if (off_y==vRez-256) off_y<=0;
    if (off_y==9'b111111111) off_y<=vRez-257;
  end

endmodule
