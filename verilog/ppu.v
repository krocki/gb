module ppu #(
 )(
  input clk,
  input resetn,
  output reg[12:0] vram_addr_a,
  input [7:0] vram_data_a,
  output reg[12:0] vram_addr_b_1st,
  input [7:0] vram_data_b_1st, vram_data_b1_1st,
  output reg[12:0] vram_addr_b_2nd,
  input [7:0] vram_data_b_2nd, vram_data_b1_2nd,
  output reg[12:0] vram_addr_c,
  input [7:0] vram_data_c, vram_data_c1,
  output reg[15:0] fb_addr,
  output reg[1:0] fb_data,
  input [7:0] lyc,
  input [7:0] objpal0,
  input [7:0] objpal1,
  input [7:0] bgrdpal,
  input [7:0] sy,
  input [7:0] sx,
  input [7:0] winy,
  input [7:0] winx,
  output reg [7:0] scanline,
  input [4:0] lcdstat_hi,
  output reg [2:0] lcdstat_lo,
  input [7:0] lcdc,
  output reg buf_no,
  input mode,
  output reg interrupt,
  output reg lstat_irq,
  input lstat_irq_ack,
  output reg vblank,
  input btn_a,
  input btn_b,
  input oam_dma,
  input [7:0] dma_data,
  input lcd_color,
  input [15:0] cpu_addr,
  input cpu_w,
  output reg [7:0] oam_do_cpu,
  input [7:0] oam_di_cpu
);

  reg [7:0] dma_bytes = 0;
  reg [7:0] xa, ya, xb, yb, xc, yc, xd, yd, xe, ye;
  wire[4:0] tile_x = xa[7:3]; wire[4:0] tile_y = ya[7:3];
  wire[9:0] tile_no = {tile_y, tile_x};
  wire[2:0] pix_x = xe[2:0]; wire[2:0] pix_y = yc[2:0];
  //wire [1:0] c = {vram_data_b1[7-pix_x], vram_data_b[7-pix_x]};
  //bg
  wire [7:0] bya = ya + sy; wire [7:0] bxa = xa + sx; wire [7:0] byc = yc + sy; wire [7:0] bxe = xe + sx;
  wire[4:0] bg_tile_x = bxa[7:3]; wire[4:0] bg_tile_y = bya[7:3];
  wire [9:0] bg_tile_no = {bg_tile_y, bg_tile_x};
  wire[2:0] bg_pix_x = bxe[2:0]; wire[2:0] bg_pix_y = byc[2:0];
  //window
  wire [7:0] wya = lcdc[5] ? (ya - winy) : 8'hff; wire [7:0] wxa = xa + 7 - winx; wire [7:0] wyc = lcdc[5] ? (yc - winy) : 8'hff; wire [7:0] wxe = xe + 7 - winx;
  wire[4:0] win_tile_x = wxa[7:3]; wire[4:0] win_tile_y = wya[7:3];
  wire [9:0] win_tile_no = {win_tile_y, win_tile_x};
  wire[2:0] win_pix_x = wxe[2:0]; wire[2:0] win_pix_y = wyc[2:0];
  wire win_visible = ya >= wya && xa >= wxa;
  reg win_visible1, win_visible2;

  //sprites
  wire[7:0] spr_idx_1st = oam_data[spr_idx0_1st+2]; wire[7:0] spr_idx_2nd = oam_data[spr_idx0_2nd+2];

  // flip y
  wire[7:0] cur_spr_flags_1st = oam_data[spr_idx0_1st+3]; wire[7:0] cur_spr_flags_2nd = oam_data[spr_idx0_2nd+3];
  wire spr_flip_y_1st = cur_spr_flags_1st[6]; wire spr_flip_y_2nd = cur_spr_flags_2nd[6];
  wire spr_whichpal_1st = cur_spr_flags_1st[4]; wire spr_whichpal_2nd = cur_spr_flags_2nd[4];
  wire spr_belowbg_1st = cur_spr_flags_1st[7]; wire spr_belowbg_2nd = cur_spr_flags_2nd[7];
  //
  reg [7:0] spr_idx1_1st, spr_idx2_1st; reg [7:0] spr_idx1_2nd, spr_idx2_2nd;
  reg vis1_1st, vis2_1st, vis1_2nd, vis2_2nd, pal1_1st, pal2_1st; reg pal1_2nd, pal2_2nd;
  wire [7:0] spr_flags_1st = oam_data[(spr_idx2_1st)+3]; wire [7:0] spr_flags_2nd = oam_data[(spr_idx2_2nd)+3];
  wire [7:0] spr_pix_x_1st = xe[7:0] - oam_data[(spr_idx2_1st)+1]; wire [7:0] spr_pix_x_2nd = xe[7:0] - oam_data[(spr_idx2_2nd)+1];
  wire [7:0] spr_pix_y_1st = yc[7:0] - oam_data[(lcdc[2] ? {spr_idx0_1st[7:1],1'b0} : spr_idx0_1st)+0];
  wire [7:0] spr_pix_y_2nd = yc[7:0] - oam_data[(lcdc[2] ? {spr_idx0_2nd[7:1],1'b0} : spr_idx0_2nd)+0];
  wire [7:0] spr_pix_y_f_1st = spr_flip_y_1st ? ~spr_pix_y_1st : spr_pix_y_1st;
  wire [7:0] spr_pix_y_f_2nd = spr_flip_y_2nd ? ~spr_pix_y_2nd : spr_pix_y_2nd;
  wire [1:0] c_spr_1st = lcd_color ? ({vram_data_b1_1st[7-pix_x[2:0]], vram_data_b_1st[7-pix_x[2:0]]}) : (spr_flags_1st[5] ? {vram_data_b1_1st[spr_pix_x_1st[2:0]], vram_data_b_1st[spr_pix_x_1st[2:0]]} : {vram_data_b1_1st[7-spr_pix_x_1st[2:0]], vram_data_b_1st[7-spr_pix_x_1st[2:0]]});
  wire [1:0] c_spr_2nd = lcd_color ? ({vram_data_b1_2nd[7-pix_x[2:0]], vram_data_b_2nd[7-pix_x[2:0]]}) : (spr_flags_2nd[5] ? {vram_data_b1_2nd[spr_pix_x_2nd[2:0]], vram_data_b_2nd[spr_pix_x_2nd[2:0]]} : {vram_data_b1_2nd[7-spr_pix_x_2nd[2:0]], vram_data_b_2nd[7-spr_pix_x_2nd[2:0]]});
  wire [1:0] c_bgd = {vram_data_c1[7-(win_visible2 ? win_pix_x : bg_pix_x)], vram_data_c[7-(win_visible2 ? win_pix_x : bg_pix_x)]};

  reg [7:0] data_a_last;
  reg[23:0] lcd_pal0[0:3];
  reg[23:0] lcd_pal1[0:3];
  reg[23:0] lcd_off_color;
  reg[23:0] palc[0:63];
  reg[7:0] oam_data[0:159];
  reg hblank = 0;

  initial begin
    $readmemh("palette.hex", palc);
    lcdstat_lo[2:0] <= 3'b000; buf_no <= 0; scanline <= 0; lstat_irq <= 0;
    lcd_off_color <= 24'h222222;
    lcd_pal1[0] = 24'hfafafa; lcd_pal1[1] = 24'hb6b6b6; lcd_pal1[2] = 24'h676767; lcd_pal1[3] = 24'h050505; // gray
    lcd_pal0[0] = 24'hc0eee3; lcd_pal0[1] = 24'h89baae; lcd_pal0[2] = 24'h45675e; lcd_pal0[3] = 24'h202020; // gray
  end

  wire [1:0] p = (lcd_color || (((~spr_belowbg_1st || c_bgd == 0) && vis2_1st && c_spr_1st > 2'b00) || ((~spr_belowbg_2nd || c_bgd == 0) && vis2_2nd && c_spr_2nd > 2'b00))) ? ((c_spr_1st > 2'b00) ? (pal2_1st ? objpal1[2*c_spr_1st+1-:2] : objpal0[2*c_spr_1st+1-:2]) : (pal2_2nd ? objpal1[2*c_spr_2nd+1-:2] : objpal0[2*c_spr_2nd+1-:2])) : bgrdpal[2*c_bgd+1-:2];
  wire [39:0] spr_visible_cmp;

  genvar ii;
  for (ii = 0; ii < 40; ii = ii+1) begin
      assign spr_visible_cmp[ii] = ( ((oam_data[(4*ii)+0]) <= (yc+16)) && ((oam_data[(4*ii)+0]) > (yc+8-8*lcdc[2])) && ((oam_data[(4*ii)+1]) <= (xc+8)) && ((oam_data[(4*ii)+1]) > (xc)));
  end

  wire spr_visible_1st = lcdc[1] && (spr_visible_cmp > 0);
  // todo
  /////////////////////
  wire [39:0] spr_lsb = spr_visible_cmp[39:0] & ~(spr_visible_cmp[39:0] - 40'd1); // extract lowest bit set
  //wire[7:0] spr_idx = oam_data[(4*$log2(spr_lsb))+2];
  wire [39:0] spr_visible_cmp_2nd = spr_visible_cmp & ~spr_lsb;
  wire spr_visible_2nd = lcdc[1] && (spr_visible_cmp_2nd > 0);

  wire[7:0] spr_idx0_1st = spr_visible_cmp[ 0] ? (4* 0) : ( spr_visible_cmp[ 1] ? (4* 1) : (
                       spr_visible_cmp[ 2] ? (4* 2) : ( spr_visible_cmp[ 3] ? (4* 3) : (
                       spr_visible_cmp[ 4] ? (4* 4) : ( spr_visible_cmp[ 5] ? (4* 5) : (
                       spr_visible_cmp[ 6] ? (4* 6) : ( spr_visible_cmp[ 7] ? (4* 7) : (
                       spr_visible_cmp[ 8] ? (4* 8) : ( spr_visible_cmp[ 9] ? (4* 9) : (
                       spr_visible_cmp[10] ? (4*10) : ( spr_visible_cmp[11] ? (4*11) : (
                       spr_visible_cmp[12] ? (4*12) : ( spr_visible_cmp[13] ? (4*13) : (
                       spr_visible_cmp[14] ? (4*14) : ( spr_visible_cmp[15] ? (4*15) : (
                       spr_visible_cmp[16] ? (4*16) : ( spr_visible_cmp[17] ? (4*17) : (
                       spr_visible_cmp[18] ? (4*18) : ( spr_visible_cmp[19] ? (4*19) : (
                       spr_visible_cmp[20] ? (4*20) : ( spr_visible_cmp[21] ? (4*21) : (
                       spr_visible_cmp[22] ? (4*22) : ( spr_visible_cmp[23] ? (4*23) : (
                       spr_visible_cmp[24] ? (4*24) : ( spr_visible_cmp[25] ? (4*25) : (
                       spr_visible_cmp[26] ? (4*26) : ( spr_visible_cmp[27] ? (4*27) : (
                       spr_visible_cmp[28] ? (4*28) : ( spr_visible_cmp[29] ? (4*29) : (
                       spr_visible_cmp[30] ? (4*30) : ( spr_visible_cmp[31] ? (4*31) : (
                       spr_visible_cmp[32] ? (4*32) : ( spr_visible_cmp[33] ? (4*33) : (
                       spr_visible_cmp[34] ? (4*34) : ( spr_visible_cmp[35] ? (4*35) : (
                       spr_visible_cmp[36] ? (4*36) : ( spr_visible_cmp[37] ? (4*37) : (
                       spr_visible_cmp[38] ? (4*38) : ( spr_visible_cmp[39] ? (4*39) : (
                       8'd160 ))))))))))))))))))))))))))))))))))))))));

  wire[7:0] spr_idx0_2nd = spr_visible_cmp_2nd[ 0] ? (4* 0) : ( spr_visible_cmp_2nd[ 1] ? (4* 1) : (
                           spr_visible_cmp_2nd[ 2] ? (4* 2) : ( spr_visible_cmp_2nd[ 3] ? (4* 3) : (
                           spr_visible_cmp_2nd[ 4] ? (4* 4) : ( spr_visible_cmp_2nd[ 5] ? (4* 5) : (
                           spr_visible_cmp_2nd[ 6] ? (4* 6) : ( spr_visible_cmp_2nd[ 7] ? (4* 7) : (
                           spr_visible_cmp_2nd[ 8] ? (4* 8) : ( spr_visible_cmp_2nd[ 9] ? (4* 9) : (
                           spr_visible_cmp_2nd[10] ? (4*10) : ( spr_visible_cmp_2nd[11] ? (4*11) : (
                           spr_visible_cmp_2nd[12] ? (4*12) : ( spr_visible_cmp_2nd[13] ? (4*13) : (
                           spr_visible_cmp_2nd[14] ? (4*14) : ( spr_visible_cmp_2nd[15] ? (4*15) : (
                           spr_visible_cmp_2nd[16] ? (4*16) : ( spr_visible_cmp_2nd[17] ? (4*17) : (
                           spr_visible_cmp_2nd[18] ? (4*18) : ( spr_visible_cmp_2nd[19] ? (4*19) : (
                           spr_visible_cmp_2nd[20] ? (4*20) : ( spr_visible_cmp_2nd[21] ? (4*21) : (
                           spr_visible_cmp_2nd[22] ? (4*22) : ( spr_visible_cmp_2nd[23] ? (4*23) : (
                           spr_visible_cmp_2nd[24] ? (4*24) : ( spr_visible_cmp_2nd[25] ? (4*25) : (
                           spr_visible_cmp_2nd[26] ? (4*26) : ( spr_visible_cmp_2nd[27] ? (4*27) : (
                           spr_visible_cmp_2nd[28] ? (4*28) : ( spr_visible_cmp_2nd[29] ? (4*29) : (
                           spr_visible_cmp_2nd[30] ? (4*30) : ( spr_visible_cmp_2nd[31] ? (4*31) : (
                           spr_visible_cmp_2nd[32] ? (4*32) : ( spr_visible_cmp_2nd[33] ? (4*33) : (
                           spr_visible_cmp_2nd[34] ? (4*34) : ( spr_visible_cmp_2nd[35] ? (4*35) : (
                           spr_visible_cmp_2nd[36] ? (4*36) : ( spr_visible_cmp_2nd[37] ? (4*37) : (
                           spr_visible_cmp_2nd[38] ? (4*38) : ( spr_visible_cmp_2nd[39] ? (4*39) : (
                           8'd160 ))))))))))))))))))))))))))))))))))))))));

  always @(posedge clk) begin
    if (~resetn) begin
      xa <= 0; ya <= 0; xe <= 0; ye <= 0; vram_addr_a <= 0; vram_addr_b_1st <= 0; vram_addr_b_2nd <= 0; fb_addr <= 0; fb_data <= 0; scanline <= 0; dma_bytes <= 0;
    end else begin
      //if (lcdc[7]) begin
        if (xa == 255) begin // extra 96 pixels
          if (ya == 193) begin ya <= 0; scanline <= 0; buf_no <= ~buf_no; end else begin ya <= ya + 1; scanline <= scanline + 1; end
          xa <= 0;
        end
        else xa <= xa + 1;
        xb <= xa; yb <= ya; xc <= xb; yc <= yb; xd <= xc; yd <= yc; ye <= yd; xe <= xd;
        spr_idx2_1st <= spr_idx1_1st; spr_idx1_1st <= spr_idx0_1st;
        spr_idx2_2nd <= spr_idx1_2nd; spr_idx1_2nd <= spr_idx0_2nd;
        vis2_1st <= vis1_1st; vis1_1st <= spr_visible_1st;
        vis2_2nd <= vis1_2nd; vis1_2nd <= spr_visible_2nd;
        pal2_1st <= pal1_1st; pal1_1st <= spr_whichpal_1st;
        pal2_2nd <= pal1_2nd; pal1_2nd <= spr_whichpal_2nd;
        win_visible2 <= win_visible1; win_visible1 <= win_visible;

        vram_addr_a <= win_visible ? ((lcdc[6] ? 13'h1c00 : 13'h180) + win_tile_no) : ((lcdc[3] ? 13'h1c00 : 13'h1800) + bg_tile_no);

        // spr
        vram_addr_b_1st <= lcd_color ? (13'h8000 + tile_no*16 + pix_y*2) : (lcdc[2] ? (13'h8000 + (({spr_idx_1st[7:1], 1'b0})*16 + {(spr_pix_y_f_1st[3:0]) , 1'b0})) : (13'h8000 + (spr_idx_1st*16 + {(spr_pix_y_f_1st[2:0]) , 1'b0})));
        vram_addr_b_2nd <= lcd_color ? (13'h8000 + tile_no*16 + pix_y*2) : (lcdc[2] ? (13'h8000 + (({spr_idx_2nd[7:1], 1'b0})*16 + {(spr_pix_y_f_2nd[3:0]) , 1'b0})) : (13'h8000 + (spr_idx_2nd*16 + {(spr_pix_y_f_2nd[2:0]) , 1'b0})));
        // bg
        vram_addr_c <= lcdc[4] ?
              (                    13'h8000 + (vram_data_a*16 + (win_visible2 ? win_pix_y : bg_pix_y)*2) ) :
              (
                vram_data_a[7]  ? (13'h8800 + ((vram_data_a[6:0])*16 + (win_visible2 ? win_pix_y : bg_pix_y)*2) ):
                                  (13'h8800 + ((128+vram_data_a)*16 + (win_visible2 ? win_pix_y : bg_pix_y)*2) )
              );


        if (ye >= 144 && oam_dma) begin
          oam_data[dma_bytes] <= dma_data;
          dma_bytes <= dma_bytes+1;
        end else begin
          dma_bytes <= 0;
        end
        //non-dma write
        if (cpu_addr[15:0] >= 16'hfe00 && cpu_addr[15:0] < 16'hfea0) begin
          oam_do_cpu <= oam_data[cpu_addr[7:0]];
          if (cpu_w) oam_data[cpu_addr[7:0]] <= oam_di_cpu[7:0];
        end
        if (mode) begin
          fb_addr <= {yc, xc}; //fb_data <= [spr_idx0_1st[7:2] + spr_idx0_2nd[7:2]];
          if (ye >= 144 && oam_dma) begin oam_data[dma_bytes] <= dma_data; dma_bytes <= dma_bytes+1; end
        end else begin
          if (ye < 144 && xe < 160) begin
            fb_data <= p; //lcd_color ? lcd_pal0[p] : lcd_pal1[p];
            fb_addr <= {ye, xe};
          end else begin
            if (ye >= 144 && oam_dma) begin
              //fb_data <= {dma_bytes, dma_data} ;
            end else begin
              if (xe < 160) begin
                fb_data <= 2;
                hblank <= 0;
              end else begin
                fb_data <= 2;
                hblank <= 1;// h blank
              end
            end
            fb_addr <= {ye, xe};
          end
        end

        if (ye == lyc) lcdstat_lo[2] <= 1'b1; else lcdstat_lo[2] <= 1'b0;
        lcdstat_lo[1:0] <= (ye > 158) ? 2'b01 : ((xe > 159) ? 2'b00 : ((xe > 10) ? 2'b11 : 2'b10));
        if (ye == 158 && xe == 159) begin vblank <= 1; end
        else if (ye == 193 && xe == 159) begin vblank <= 0; end
        if (ye == 158 && xe == 159) interrupt <= 1; else interrupt <= 0;
        if (lstat_irq_ack) lstat_irq <= 0;
        else if (
             (lcdstat_hi[3] && lyc == ye && xe == 159) ||
             (lcdstat_hi[2] && xe == 159) ||
             (lcdstat_hi[1] && xe == 159 && ye == 158) ||
             (lcdstat_hi[0] && xe == 10)
           ) lstat_irq <= 1;
      end
    end
  //end
endmodule
