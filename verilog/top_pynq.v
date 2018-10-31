parameter romfile = `ROM; //"mario.hex";
parameter USE_MBC1 = 1;
parameter USE_BOOTROM = 1;
parameter USE_7SEG = 1;

module top (
    // clock
    input clk,
    // rst btn
    //input rst_n,
    // switches
    input[1:0] sw,
    // buttons
    input[3:0] btn,
    // LEDs
    output[3:0] led,
    output[5:0] led_rgb,
    //sseg display
    // PMOD outputs
    inout[7:0] ja,
    output [7:0] jb,
    // HDMI
    output[2:0] data_p,
    output[2:0] data_n,
    output clk_p,
    output clk_n,
    input[13:0] ck_io

);

  wire[3:0] vga_r;
  wire[3:0] vga_b;
  wire[3:0] vga_g;
  wire vga_hs;
  wire vga_vs;

  wire[15:0] vram_a0;    // address
  wire[15:0] vram_a1;    // address
  wire[7:0]  vram_o0;     // output data
  wire[7:0]  vram_o1;     // debug output data

  wire[15:0] a0;    // address
  wire[15:0] a1;    // address
  wire[7:0] o0;     // output data
  wire[7:0] o1;     // debug output data

  reg clk_1k, clk_1M;
  reg[3:0] cnt0; // ~4MHz
  reg[5:0] cnt1; // ~0.5MHz
  always @(posedge clk) begin
    cnt0 <= cnt0 + 1; cnt1 <= cnt1 + 1;
    if (cnt0 == 0) clk_1k <= ~clk_1k;
    if (cnt1 == 0) clk_1M <= ~clk_1M;
  end

  wire vga_clk, ppu_clk;
  wire[15:0] vram_in_addr;
  wire[7:0]  vram_in_data;
  wire[15:0] vram_out_addr_a, vram_out_addr_b_1st, vram_out_addr_b_2nd, vram_out_addr_c;
  wire[7:0]  vram_out_data_a, vram_out_data_b_1st, vram_out_data_b1_1st, vram_out_data_b_2nd, vram_out_data_b1_2nd, vram_out_data_c, vram_out_data_c1;
  wire[15:0] fb_in_addr;
  wire[15:0] fb_out_addr;
  wire[23:0] fb_in_data;
  wire[23:0] fb_out_data0, fb_out_data1, fb_out_data;
  wire[3:0] fb_btn;// = btn[3:0];
  wire[3:0] ppu_btn;// = btn[3:0];

  wire gb_clk = ~dbg_btn[1] ? (sw[1] ? clk_1k : clk_1M) : clk;
  //wire gb_clk = (sw[1] ? clk_1k : clk_1M);

  wire [7:0] cpu_din;
  wire cpu_write;
  wire[7:0] cpu_dout;
  wire[7:0] last_op;
  wire[15:0] cpu_addr;
  wire resetn = sw[0]; //~btn[0];
  wire[7:0] iack, iflags, inte;
  wire buf_no;
  wire [7:0] scanline, lcdstat;

  wire ppu_irq, lstat_irq;
  wire vblank;
  wire [7:0] lcdc;
  wire oam_dma;
  wire [7:0] oam_src;
  wire [7:0] dma_bytes;
  wire [7:0] dma_data;
  wire [7:0] lyc;
  wire [7:0] rom_bank, ram_bank;

  wire [ 7:0] vram_out_cpu_data;

  // ppu regs
  wire [7:0] bgrdpal, objpal0, objpal1, sy, sx, winx, winy;
  wire [31:0] tim;
  wire [11:0] button_o;
  ButtonScanner bt0(.clk_i(clk), .b_io(ja[3:0]), .button_o(button_o));
  wire key_down, key_up, key_left, key_right, key_sel, key_start, key_a, key_b;
  wire [7:0] joypad = {key_down, key_up, key_left, key_right, key_sel, key_start, key_b, key_a};
  assign {key_down, key_up, key_left, key_right} = {button_o[0], button_o[1], button_o[6], button_o[7]};
  assign {key_sel, key_start, key_a, key_b} = {button_o[2], button_o[8], button_o[5], button_o[11]};

  wire [3:0] dbg_btn = {button_o[4:3], button_o[10:9]};
  wire [7:0] oam_read_data;

  mmu #(.romfile(romfile), .BOOTROM_EN(USE_BOOTROM), .USE_MBC1(USE_MBC1)) mmu0(.clk(gb_clk), .rom_we(ck_io[0]), .resetn(resetn), .vram_addr(vram_in_addr), .vram_data(vram_in_data), .data_in(cpu_dout), .data(cpu_din), .addr(cpu_addr), .we(cpu_write), .iflags(iflags), .iack(iack), .inte(inte), .objpal0(objpal0), .objpal1(objpal1), .bgrdpal(bgrdpal), .sy(sy), .sx(sx), .winy(winy), .winx(winx), .scanline(scanline), .ppu_irq(ppu_irq), .lstat_irq(lstat_irq), .lcdstat_lo(lcdstat[2:0]), .lcdstat_hi(lcdstat[7:3]), .joypad(~joypad[7:0]), .tim(tim), .lyc(lyc), .lcdc(lcdc), .oam_dma(oam_dma), .oam_src(oam_src), .dma_bytes(dma_bytes), .dma_data(dma_data), .rom_bank(rom_bank), .ram_bank(ram_bank), .vram_out_cpu_data(vram_out_cpu_data), .oam_read_data(oam_read_data) );

  gbcpu #(.BOOTROM_EN(USE_BOOTROM))
   gbcpu_inst (
   .clk(gb_clk),
   .resetn(resetn),
   .cpu_din(cpu_din),
   .cpu_dout(cpu_dout),
   .addr(cpu_addr),
   .cpu_write(cpu_write),
   .cpu_op(last_op),
   .iflags(iflags),
   .iack(iack)
  );

  wire [6:0] spr_start_idx;
  ppu (.clk(gb_clk), .resetn(resetn), .mode(dbg_btn[0]), .lcd_color(btn[2]), .btn_a(0), .btn_b(dbg_btn[1]),
       .vram_addr_a(vram_out_addr_a), .vram_data_a(vram_out_data_a),
       .vram_addr_b_1st(vram_out_addr_b_1st), .vram_data_b_1st(vram_out_data_b_1st), .vram_data_b1_1st(vram_out_data_b1_1st),
       .vram_addr_b_2nd(vram_out_addr_b_2nd), .vram_data_b_2nd(vram_out_data_b_2nd), .vram_data_b1_2nd(vram_out_data_b1_2nd),
       .vram_addr_c(vram_out_addr_c), .vram_data_c(vram_out_data_c), .vram_data_c1(vram_out_data_c1),
       .objpal0(objpal0), .objpal1(objpal1), .fb_addr(fb_in_addr), .fb_data(fb_in_data), .buf_no(buf_no), .bgrdpal(bgrdpal), .sy(sy), .sx(sx), .winy(winy), .winx(winx), .scanline(scanline), .lyc(lyc), .interrupt(ppu_irq), .lstat_irq_ack(iack[1]), .lstat_irq(lstat_irq), .vblank(vblank), .lcdstat_lo(lcdstat[2:0]), .lcdstat_hi(lcdstat[7:3]), .lcdc(lcdc), .oam_dma(oam_dma), .dma_data(dma_data), .cpu_addr(cpu_addr), .cpu_w(cpu_write), .oam_di_cpu(cpu_dout), .oam_do_cpu(oam_read_data)
      );

  //todo: clean up
  framebuffer #(.W(8192), .H(1), .B(8), .D("vram_init.hex")) (
      .clk_in(gb_clk), .addr_in(vram_in_addr), .data_in(vram_in_data), .we(1),
      .clk_out(gb_clk), .addr_out(vram_out_addr_a), .data_out(vram_out_data_a) );

  framebuffer #(.W(8192), .H(1), .B(8), .D("vram_init.hex")) ( // vram
      .clk_in(gb_clk), .addr_in(vram_in_addr), .data_in(vram_in_data), .we(1),
      .clk_out(gb_clk), .addr_out(vram_out_addr_b_1st), .data_out(vram_out_data_b_1st) );

  framebuffer #(.W(8192), .H(1), .B(8), .D("vram_init.hex")) ( // vram
      .clk_in(gb_clk), .addr_in(vram_in_addr), .data_in(vram_in_data), .we(1),
      .clk_out(gb_clk), .addr_out(vram_out_addr_b_1st+1), .data_out(vram_out_data_b1_1st) );

  framebuffer #(.W(8192), .H(1), .B(8), .D("vram_init.hex")) ( // vram
      .clk_in(gb_clk), .addr_in(vram_in_addr), .data_in(vram_in_data), .we(1),
      .clk_out(gb_clk), .addr_out(vram_out_addr_b_2nd), .data_out(vram_out_data_b_2nd) );

  framebuffer #(.W(8192), .H(1), .B(8), .D("vram_init.hex")) ( // vram
      .clk_in(gb_clk), .addr_in(vram_in_addr), .data_in(vram_in_data), .we(1),
      .clk_out(gb_clk), .addr_out(vram_out_addr_b_2nd+1), .data_out(vram_out_data_b1_2nd) );

  framebuffer #(.W(8192), .H(1), .B(8), .D("vram_init.hex")) ( // vram
      .clk_in(gb_clk), .addr_in(vram_in_addr), .data_in(vram_in_data), .we(1),
      .clk_out(gb_clk), .addr_out(cpu_addr[12:0]), .data_out(vram_out_cpu_data) );

  framebuffer #(.W(8192), .H(1), .B(8), .D("vram_init.hex")) ( // vram
      .clk_in(gb_clk), .addr_in(vram_in_addr), .data_in(vram_in_data), .we(1),
      .clk_out(gb_clk), .addr_out(vram_out_addr_c), .data_out(vram_out_data_c) );

  framebuffer #(.W(8192), .H(1), .B(8), .D("vram_init.hex")) ( // vram
      .clk_in(gb_clk), .addr_in(vram_in_addr), .data_in(vram_in_data), .we(1),
      .clk_out(gb_clk), .addr_out(vram_out_addr_c+1), .data_out(vram_out_data_c1) );

  framebuffer #(.W(256), .H(256), .B(24), .D("fb_gray.hex")) ( // framebuffer 0
      .clk_in(gb_clk), .addr_in(fb_in_addr), .data_in(fb_in_data), .we(buf_no),
      .clk_out(vga_clk), .addr_out(fb_out_addr), .data_out(fb_out_data0) );

  framebuffer #(.W(256), .H(256), .B(24), .D("fb_gray.hex")) ( // framebuffer 1
      .clk_in(gb_clk), .addr_in(fb_in_addr), .data_in(fb_in_data), .we(~buf_no),
      .clk_out(vga_clk), .addr_out(fb_out_addr), .data_out(fb_out_data1) );

  assign fb_out_data = buf_no ? fb_out_data1 : fb_out_data0; // double buffering
  assign led_rgb[0] = iflags[0]; // ld4 blue
  assign led_rgb[1] = iflags[1]; // ld4 green
  assign led_rgb[2] = iflags[2]; // ld4 red
  //assign led_rgb[3] = cpu_addr >= 16'hc000 && cpu_addr < 16'hfe00;   // ld5 blue
  assign led_rgb[4] = cpu_addr >= 16'ha000 && cpu_addr < 16'hc000;   // ld4 green
  assign led_rgb[5] = cpu_addr >= 16'h8000 && cpu_addr < 16'ha000;   // ld4 red

  assign led[3] = cpu_write; assign led[2] = oam_dma;
  assign led[1] = cpu_addr >= 16'hff80 && cpu_addr < 16'hffff;
  assign led[0] = (cpu_addr >= 16'hff00 && cpu_addr < 16'hff80) || cpu_addr == 16'hffff;
  //assign led[3] = cpu_addr == 16'hffff;
  //assign led[2] = vblank;
  //assign led_rgb[1] = cpu_addr >= 16'hff40 && cpu_addr < 16'hff4c; // ld4 green
  reg [23:0] lcd_pal1[0:3];
  initial begin
    lcd_pal1[0] = 24'hefefef;
    lcd_pal1[1] = 24'hb6b6b6;
    lcd_pal1[2] = 24'h676767;
    lcd_pal1[3] = 24'h050505; // gray
  end
  wire [23:0] color = lcd_pal1[fb_out_data];
  dvid_test dtest (.ppu_addr(fb_in_addr), .vga_clk(vga_clk), .clk_in(clk), .data_p(data_p), .data_n(data_n), .clk_p(clk_p), .clk_n(clk_n), .va(fb_out_addr), .vd(color), .sw(2'b11), .btn(fb_btn));

  generate if (USE_7SEG)
    led_hex_display xs1(.clk_i(clk), .hexAllDigits_i({cpu_addr[15:0], rom_bank, ram_bank}), .ledDrivers_o(jb[7:0]));
  endgenerate

endmodule
