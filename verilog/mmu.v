`timescale 1 ns / 1 ps

module mmu(clk, rom_we, resetn, vram_addr, vram_data, addr, data, rom_bank, ram_bank, bgrdpal, objpal0, objpal1, scanline, lcdstat_hi, lcdstat_lo, lcdc, oam_src, oam_dma, dma_bytes, dma_data, lyc, sx, sy, winx, winy, ppu_irq, lstat_irq, joypad, data_in, we, iflags, inte, iack, tim, vram_out_cpu_data, oam_read_data);
  parameter romfile = "07.hex";
  parameter BOOTROM_EN = 0;
  parameter USE_MBC1 = 0;
  input clk;
  input resetn;
  input [15:0] addr;
  output [7:0] data;
  input [7:0] data_in;
  output reg [12:0] vram_addr;
  output reg [7:0] vram_data;
  output reg [7:0] bgrdpal;
  output reg [7:0] objpal0;
  output reg [7:0] objpal1;
  output reg [7:0] sy;
  output reg [7:0] lyc;
  output reg [7:0] sx;
  output reg [7:0] winy;
  output reg [7:0] winx;
  output reg [7:0] lcdc;
  output reg [15:0] oam_src;
  output reg oam_dma;
  output reg [7:0] dma_bytes;
  output [7:0] dma_data;
  input [7:0] scanline;
  input [2:0] lcdstat_lo;
  output reg [4:0] lcdstat_hi;
  input ppu_irq, lstat_irq;
  input rom_we;
  input [7:0] joypad;
  reg [3:0] joypad_select = 0;

  input we;
  output[7:0] iflags;
  input[7:0] iack;
  output [7:0] inte;
  reg [7:0] data_non_bram;
  output wire [31:0] tim;
  reg bootrom_off;
  input [7:0] vram_out_cpu_data;
  input [7:0] oam_read_data;
  integer i;

  // timer
  wire [7:0] tima, div; reg [7:0] tac, tma; reg tima_w; wire tim_irq, tim_zero;
  timer tim0(.clk(clk), .resetn(resetn), .tima_w(tima_w), .tima(tima), .div(div), .tac(tac), .tma(tma), .interrupt(tim_irq), .ack(iack[2]), .is_zero(tim_zero));
  assign tim = {tima, div, tac, tma};
  reg [7:0] iflags = 0; // interrupt flags register  (0xff0f)
  reg [7:0] inte;       // interrupt enable register (0xffff)

  reg oam = 0; reg vram = 0; reg cart = 0; reg rom = 1; reg hram = 0; reg ioregs = 0; reg ram = 0; reg cc = 0;
  wire ram_we = we & (addr >= 16'hc000 && addr < 16'hfe00);
  wire hram_we = we & (addr >= 16'hff80 && addr < 16'hffff);
  wire ioregs_we = we & (addr >= 16'hff00 && addr < 16'hff80);
  wire [7:0] cart_do, bootrom_do, hram_do, ioregs_do, ram_do;
  output reg [7:0] rom_bank = 8'd1;
  output reg [7:0] ram_bank = 8'd0;
  rams #(.D("bootrom0.hex"), .A( 8)) (.clk(clk), .di(8'hxx),   .we(1'b0), .addr(addr[7:0]), .do(bootrom_do));

  // MBC1 - 128kB
    // wire [16:0] cart_addr = (USE_MBC1) ? (addr[14] ? ( {rom_bank[2:0], addr[13:0]} ) : {2'b00, addr[14:0] }) : {2'b00, addr[14:0]}; //(addr < 16'h4000) ? addr : (addr[14:0] + rom_bank * 16'h4000 );
    // rams #(.D(romfile),       .A(17)) (.clk(clk), .di(8'hxx),   .we(1'b0), .addr(oam_dma ? oam_src[14:0] : (addr == 16'hff46 ? {data_in[6:0], 8'h00} : cart_addr[16:0])), .do(cart_do));
    // 64kB
    wire [15:0] cart_addr = (USE_MBC1) ? (addr[14] ? ( {rom_bank[1:0], addr[13:0]} ) : {1'b0, addr[14:0] }) : {1'b0, addr[14:0]}; //(addr < 16'h4000) ? addr : (addr[14:0] + rom_bank * 16'h4000 );
    rams #(.D(romfile),       .A(17)) (.clk(clk), .di(8'hxx),   .we(1'b0), .addr(oam_dma ? oam_src[14:0] : (addr == 16'hff46 ? {data_in[6:0], 8'h00} : cart_addr[15:0])), .do(cart_do));
  // no MBC1
    //rams #(.D(romfile),       .A(15)) (.clk(clk), .di(8'hxx),   .we(1'b0), .addr(oam_dma ? oam_src[14:0] : (addr == 16'hff46 ? {data_in[6:0], 8'h00} : addr[14:0])), .do(cart_do));

  rams #(.D("hram.hex"),    .A( 7)) (.clk(clk), .di(data_in), .we(hram_we), .addr(addr[6:0]), .do(hram_do));
  rams #(.D("zero.hex"),    .A(13)) (.clk(clk), .di(data_in), .we(ram_we), .addr(oam_dma ? oam_src[12:0] : (addr == 16'hff46 ? {data_in[4:0], 8'h00} : addr[12:0])), .do(ram_do));
  rams #(.D("ioregs.hex"),  .A( 7)) (.clk(clk), .di(data_in), .we(ioregs_we), .addr(addr[6:0]), .do(ioregs_do));

  assign data[7:0] = (cc > 0) ? ( rom ? ((bootrom_off | cart) ? cart_do : bootrom_do) : (hram ? hram_do : (ioregs ? ioregs_do : (ram ? (oam_dma ? 8'hxx : ram_do) : (vram ?  vram_out_cpu_data : (oam ? oam_read_data : data_non_bram[7:0])))))) : 8'hzz;

  //wire vblank = scanline >= 144;
  assign dma_data[7:0] = oam_dma ? ram_do : 8'hxx;
  always @(posedge clk)
  begin

    if (~resetn) begin rom_bank <= 8'd1; vram <= 0; ram <= 0; ioregs <= 0; hram <= 0; rom <= 1; cart <= 0; cc <= 0; dma_bytes <= 0; oam_dma <= 0; oam_src <= 0; lcdc <= 8'h00; inte <= 8'h00; iflags <= 8'h00; bootrom_off <= ~BOOTROM_EN; vram_addr <= 0; vram_data <= 0; lyc <= 0; objpal0 <=0; objpal1 <= 0; bgrdpal <= 0; winy <= 0; winx <= 0; sx <= 0; sy <= 0; tima_w <= 0; tma <= 0; tac <= 0; end
    else begin
      cc <= 1;
      if (oam_dma) begin
        if (dma_bytes == 0) oam_dma <= 0;
        else begin dma_bytes <= dma_bytes - 1; oam_src <= oam_src + 1; end // OAM DMA transfer in progress
      end

      if (tima_w) tima_w <= 0;
      if (iack[2]) iflags[2] <= 1'b0; else if (tim_irq & inte[2]) iflags[2] <= 1'b1;
      if (iack[1]) iflags[1] <= 1'b0; else if (lstat_irq & inte[1]) iflags[1] <= 1'b1;
      if (iack[0]) iflags[0] <= 1'b0; else if (ppu_irq & inte[0]) iflags[0] <= 1'b1;

      hram <= 0; rom <= 0; cart <= 0; ioregs <= 0; ram <= 0; vram <= 0;

      if (we) begin
        if (addr < 16'h8000) //begin cart[addr[14:0]] <= data_in; end // cart
        begin
          if (addr >= 16'h2000 && addr < 16'h4000) rom_bank <= (data_in[4:0] == 5'd0) ? 5'd1 : data_in[4:0];
          if (addr >= 16'h4000 && addr < 16'h6000) ram_bank <= data_in[1:0];
        end
        if (addr >= 16'h8000 && addr <= 16'h9fff) begin vram_addr <= addr[12:0]; vram_data <= data_in; end // vram
        else if (addr == 16'hff00) joypad_select <= data_in[7:4];
        else if (addr == 16'hff05) tima_w <= 1;
        else if (addr == 16'hff06) tma <= data_in;
        else if (addr == 16'hff07) tac <= data_in;
        else if (addr == 16'hff0f) iflags <= data_in;
        else if (addr == 16'hff40) lcdc <= data_in;
        else if (addr == 16'hff41) lcdstat_hi[4:0] <= data_in[7:3];
        else if (addr == 16'hff42) sy <= data_in;
        else if (addr == 16'hff43) sx <= data_in;
        else if (addr == 16'hff44) ; //begin scanline <= data_in; end
        else if (addr == 16'hff45) lyc <= data_in; //begin scanline <= data_in; end
        else if (addr == 16'hff46) begin oam_dma <= 1; dma_bytes <= 8'd159; oam_src <= {data_in[7:0], 8'h01}; end
        else if (addr == 16'hff47) bgrdpal <= data_in;
        else if (addr == 16'hff48) objpal0 <= data_in;
        else if (addr == 16'hff49) objpal1 <= data_in;
        else if (addr == 16'hff4a) winy <= data_in;
        else if (addr == 16'hff4b) winx <= data_in;
        else if (addr == 16'hff50) bootrom_off <= data_in;
        else if (addr == 16'hffff) inte <= data_in;
        else if (addr >= 16'hff00 && addr < 16'hff80) ; // ioregs
        else if (addr >= 16'hc000 && addr < 16'hfe00) ; // ram[addr[12:0]] <= data_in;
        else if (addr >= 16'hff80 && addr < 16'hffff) ; // hram
        else ;
      end else begin //~we
        if (addr >= 16'h0000 && addr < 16'h0100) rom <= 1; // : cart[addr[14:0]]; end
        else if (addr >= 16'h8000 && addr <= 16'h9fff) begin vram <= 1; end // vram
        else if (addr >= 16'h0100 && addr < 16'h8000) begin rom <= 1; cart <= 1; end //data_non_bram <= cart[addr[14:0]];
        else if (addr == 16'hff00) data_non_bram <= {joypad_select[3:0], ( ({4{joypad_select[0]}} & joypad[3:0]) | ({4{joypad_select[1]}} & joypad[7:4]))};
        else if (addr == 16'hff04) data_non_bram <= div;
        else if (addr == 16'hff05) data_non_bram <= tima;
        else if (addr == 16'hff0f) data_non_bram <= iflags;
        else if (addr == 16'hff40) data_non_bram <= lcdc;
        else if (addr == 16'hff41) data_non_bram <= {lcdstat_hi[4:0], lcdstat_lo[2:0]};
        else if (addr == 16'hff42) data_non_bram <= sy;
        else if (addr == 16'hff43) data_non_bram <= sx;
        else if (addr == 16'hff44) data_non_bram <= scanline;
        else if (addr == 16'hff45) data_non_bram <= lyc;
        else if (addr == 16'hff47) data_non_bram <= bgrdpal;
        else if (addr == 16'hff48) data_non_bram <= objpal0;
        else if (addr == 16'hff49) data_non_bram <= objpal1;
        else if (addr == 16'hff4a) data_non_bram <= winy;
        else if (addr == 16'hff4b) data_non_bram <= winx;
        else if (addr == 16'hffff) data_non_bram <= inte;
        else if (addr >= 16'hff00 && addr < 16'hff80) ioregs <= 1;
        else if (addr >= 16'hc000 && addr < 16'hfe00) ram <= 1;
        else if (addr >= 16'hff80 && addr < 16'hffff) hram <= 1;
        else ;
      end
      // serial out
      if (addr[15:0] == 16'hff01) begin // serial io
        $write("%c", data_in);
      end

      //debug
      if (addr[15:0] >= 16'hff00 && addr[15:0] < 16'hff80) begin
        if (we) begin $display("W %04x <= %02x", addr, data_in); end
        else begin $write("R %04x ", addr); #1 $write(" = %02x\n", data); end
      end
    end
  end

  //assign data[7:0] = data_non_bram[7:0];

endmodule

