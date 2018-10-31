// Copyright IBM Corp. 2018
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

module gbcpu (

  input clk,
  input resetn,

  input[7:0] cpu_din,
  output reg[7:0] cpu_dout,
  output reg cpu_write,
  output reg[15:0] addr,
  output reg[7:0] cpu_op,
  input[7:0] iflags,
  output reg[7:0] iack
);

  parameter logfile = "01.txt";
  parameter BOOTROM_EN = 0;
  reg skip_bootrom;
  reg[31:0] count_cycle = 0;
  reg[31:0] count_instr = 0;
  reg[95:0] regs;
  reg[15:0] args;
  reg[1:0] reg16;
  integer f;
  initial begin f = $fopen(logfile); end

  `define pc regs[95:80]
  `define sp regs[79-:16]
  `define bc regs[63-:16]
  `define b  regs[63-:8]
  `define c  regs[55-:8]
  `define de regs[47-:16]
  `define d  regs[47-:8]
  `define e  regs[39-:8]
  `define hl regs[31-:16]
  `define h  regs[31-:8]
  `define l  regs[23-:8]
  `define f  regs[15-:8]
  `define fz regs[15]
  `define fn regs[14]
  `define fh regs[13]
  `define fc regs[12]
  `define a  regs[7-:8]
  `define la regs[3-:4]
  `define af {`a, `f}

  reg [2:0] s = 3'b000;

  localparam f0 = 3'b000;
  localparam f1 = 3'b001;
  localparam f2 = 3'b010;
  localparam f3 = 3'b011;
  localparam w1 = 3'b101;
  localparam w2 = 3'b110;
  localparam wa = 3'b111;

  wire [7:0] opcode = (s == 0) ? cpu_din[7:0] : cpu_op;
 `define src_reg regs[63-opcode[2:0]*8-:8]
 `define dst_reg regs[63-opcode[5:3]*8-:8]
 `define dst_reg_l regs[63-opcode[5:3]*8-4-:4]

 `define imm16  {cpu_din, args[15:8] }
 `define imm8 {cpu_din}

  reg jr, jp, sta, stsp, stah, lda, ldah, ld8, ld16, pop16, ldmem, call, push;
  reg op_hl_inc, op_hl_dec, lda16, ldhl, sp_add_s8, ld_add_s8;
  reg [7:0] cpu_dout_next;
  reg ei;
  reg halted;

  wire [15:0] sp_signed_sum = cpu_din[7] ? (`sp - {1'b0, ~cpu_din[6:0]} - 1'b1) : (`sp + cpu_din);
  wire [4:0] sp_half_signed_sum = ({1'b0,regs[67:64]} + {1'b0,cpu_din[3:0]});
  wire [8:0] sp_carry_signed_sum = ({1'b0,regs[71:64]} + {1'b0,cpu_din});

  // branch condition code
  wire cc0 = // jr
          ~regs[15] & (opcode[4:3] == 3'b00)  // nz
        |  regs[15] & (opcode[4:3] == 3'b01)  // z
        | ~regs[12] & (opcode[4:3] == 3'b10)  // nc
        |  regs[12] & (opcode[4:3] == 3'b11); // c

  wire cc = opcode[0] | cc0;

  // ALU
  reg alu_imm8;
  wire [7:0] alu_c;
  wire [3:0] alu_f;
  alu alu0(.op(opcode[5:3]), .a(`a), .b(alu_imm8 ? cpu_din : regs[63-cpu_din[2:0]*8-:8]), .c(alu_c), .in_f(regs[15:12]), .f(alu_f));

  // CB ALU
  reg cb, cb_mem;
  reg [7:0] last_cb;
  wire [2:0] cb_alu_regno = cb ? cpu_din[2:0] : last_cb[2:0];
  wire [7:0] cb_alu_in = cb_alu_regno == 3'b110 ? cpu_din[7:0] : regs[63-cb_alu_regno*8-:8];
  wire [7:0] cb_alu_out;
  wire [3:0] cb_alu_f;
  cb_alu alu1(.op(cb ? cpu_din[7:3] : last_cb[7:3]), .in(cb_alu_in), .out(cb_alu_out), .in_f(regs[15:12]), .f(cb_alu_f));

  always @(posedge clk)
  begin
    if (~resetn) begin
        skip_bootrom <= ~BOOTROM_EN; count_cycle <= 0; count_instr <= 0; iack <= 0; ei <= 1; halted <= 0;
      if (skip_bootrom)
        begin `pc <= 16'h00ff; addr <= 16'h0100; `sp <= 16'hfffe; `af <= 16'h01b0; `bc <= 16'h0013; `de <= 16'h00d8; `hl <= 16'h014d;
      end else
        begin `pc <= 16'hffff; addr <= 16'h0000; `sp <= 16'h0000; `af <= 16'h0000; `bc <= 16'h0000; `de <= 16'h0000; `hl <= 16'h0000;
      end
    end else
    begin

      count_cycle <= count_cycle + 1;
      case (s)
        f0: begin // default state
          if (count_cycle > 0) $fwrite(f, "%04x %02x %04x %04x %04x %04x %04x\n", `pc, cpu_din, `sp, `bc, `de, `hl, `af);
          // service IRQs
          if (iack[0]) iack[0] <= 1'b0; if (iack[1]) iack[1] <= 1'b0; if (iack[2]) iack[2] <= 1'b0;
          if (iflags[0] && ~ei) iack[0] <= 1'b1; if (iflags[1] && ~ei) iack[1] <= 1'b1; if (iflags[2] && ~ei) iack[2] <= 1'b1;

          if (iflags[0] && ei) begin // vblank
            ei <= 0; iack[0] <= 1'b1; {cpu_dout_next, cpu_dout} <= `pc; cpu_write <= 1; s <= w2; addr <= `sp - 2;
            `pc <= {9'b000000000, 4'b1000, 3'b000}; `sp <= `sp - 2; halted <= 0;
          end else
          if (iflags[1] && ei) begin // lstat
              ei <= 0; iack[1] <= 1; {cpu_dout_next, cpu_dout} <= `pc; cpu_write <= 1; s <= w2; addr <= `sp - 2;
              `pc <= {9'b000000000, 4'b1001, 3'b000}; `sp <= `sp - 2; halted <= 0;
          end else
          if (iflags[2] && ei) begin // timer
              ei <= 0; iack[2] <= 1; {cpu_dout_next, cpu_dout} <= `pc; cpu_write <= 1; s <= w2; addr <= `sp - 2;
              `pc <= {9'b000000000, 4'b1010, 3'b000}; `sp <= `sp - 2; halted <= 0;
          end else
          // normal operation
          if (~halted) begin
              count_instr <= count_instr + 1;
              addr <= addr + 1; `pc <= `pc + 1;
              pop16 <= 1'b0; stsp <= 0; sta <= 1'b0; stah <= 1'b0; ldah <= 1'b0; lda <= 1'b0;
              jr <= 1'b0; jp <= 1'b0; ld16 <= 1'b0; ld8 <= 1'b0;
              cpu_op <= cpu_din; ldmem <=0; call <= 0; push <= 0;
              op_hl_dec <= 1'b0; op_hl_inc <= 1'b0; alu_imm8 <= 0; lda16 <= 0; cb <= 0;
              sp_add_s8 <= 0; ld_add_s8 <= 0; ldhl <= 0;

            casex (cpu_din)
              // decode and execute load/store
              8'h00: ; // nop
              8'h10: ; // stop
              8'h01, 8'h11, 8'h21, 8'h31: // ld {bc, de, hl, sp}, imm16
                     begin s <= f2; `pc <= `pc + 3; addr <= addr + 1; ld16 <= 1'b1; reg16 <= cpu_din[5:4]; end
              8'hcb: begin s <= f1; addr <= addr + 1; `pc <= `pc + 2; cb <= 1'b1; end
              8'he0: begin stah <= 1; s <= f1; `pc <= `pc + 2; addr <= addr + 1; end // ($ffxx) <= a
              8'he9: begin `pc <= `hl; addr <= `hl; s<=wa; end
              8'h08: begin stsp <= 1; s <= f2; `pc <= `pc + 3; addr <= addr + 1; end // ld (a16), sp
              8'he8: begin sp_add_s8 <= 1; s <= f1; `pc <= `pc + 2; end
              8'hf8: begin ld_add_s8 <= 1; s <= f1; `pc <= `pc + 2; end
              8'hea: begin sta <= 1; s <= f2; `pc <= `pc + 3; addr <= addr + 1; end // ld (a16), a
              8'hfa: begin s <= f2; `pc <= `pc+3; addr <= addr + 1; lda16 <= 1; end // ld A, (a16)
              8'hf0: begin ldah <= 1; s <= f1; `pc <= `pc + 2; addr <= addr + 1; end // a <= ($ffxx)
              8'h35: begin s <= f1; addr <= `hl; ldmem <= 1; op_hl_dec <= 1'b1; end // dec (hl)
              8'h34: begin s <= f1; addr <= `hl; ldmem <= 1; op_hl_inc <= 1'b1; end // inc (hl)
              8'hf3: ei <= 1'b0; // di
              8'hf9: `sp <= `hl; // ld sp, hl
              8'hfb: ei <= 1'b1; // ei
              8'h0f: begin `fc <= regs[0]; `fn <= 1'b0; `fh <= 1'b0; `fz <= 1'b0; `a <= {regs[0], regs[7:1]}; end // rrca
              8'h1f: begin `fc <= regs[0]; `fn <= 1'b0; `fh <= 1'b0; `fz <= 1'b0; `a <= {`fc, regs[7:1]}; end // rra
              8'h17: begin `fz <= 0; `fn <= 0; `fh <= 0; `fc <= regs[7]; `a <= {regs[6:0], `fc}; end // rla
              8'h07: begin `fz <= 0; `fn <= 0; `fh <= 0; `fc <= regs[7]; `a <= {regs[6:0], regs[7]}; end // rlca
              8'he2: begin cpu_write <= 1; addr <= {8'hff, `c}; s <= w1; cpu_dout <= `a; end // ld ($ff00 | C), A
              8'hf2: begin addr <= {8'hff, `c}; s <= f1; lda <= 1; end // ld A, ($ff00 + C)
              8'h2f: begin `fn <= 1; `fh <= 1; `a <= `a ^ 8'hff; end // cpl
              8'h37: begin `fn <= 0; `fh <= 0; `fc <= 1; end // scf
              8'h3f: begin `fn <= 0; `fh <= 0; `fc <= ~(`fc); end // ccf

              8'b11xxx111: // rst
              begin
                {cpu_dout_next, cpu_dout} <= addr; cpu_write <= 1; s <= w2; addr <= `sp - 2;
                `pc <= {9'b000000000, 1'b0, cpu_din[5:3], 3'b000}; `sp <= `sp - 2;
              end
              8'b110xx010, // c2 -> JP cc a16 c2, d2, ca, da
              8'b11000011: begin s <= f2; addr <= addr + 1; `pc <= `pc + 3; jp <= cc; end // c3 -> JP a16
              //01, 11, 21, 31
              8'b00xx0001: begin s <= f2; `pc <= `pc + 3; addr <= addr + 1; ld16 <= 1'b1; reg16 <= cpu_din[5:4]; end // ld R16, D16
              8'b00xx1011: // dec16
              begin
                case (cpu_din[5:4])
                  2'b00: `bc <= `bc - 1; 2'b01: `de <= `de - 1;
                  2'b10: `hl <= `hl - 1; 2'b11: `sp <= `sp - 1;
                endcase
                s <= f0;
              end
              8'b00xx0011: // inc16
              begin
                case (cpu_din[5:4])
                  2'b00: `bc <= `bc + 1; 2'b01: `de <= `de + 1;
                  2'b10: `hl <= `hl + 1; 2'b11: `sp <= `sp + 1;
                endcase
                s <= f0;
              end
              8'b11xx0001: begin s <= f3; addr <= `sp; `sp <= `sp+2; pop16 <= 1'b1; reg16 <= cpu_din[5:4]; end // pop 16
              8'b01110110: begin ; halted <= 1; ei <= 1; end
              8'b01110xxx: begin cpu_dout <= `src_reg; cpu_write <= 1'b1; addr <= `hl; s <= w1; end // ld (hl), r
              8'b01xxx110: begin s <= f1; ld8 <= 1'b1; ldmem <= 1'b1; addr <= `hl; end // ld r, (hl)
              8'b00110110: begin s <= f1; `pc <= `pc + 2; addr <= addr + 1; ldhl <= 1'b1; end // ld hl. d8
              8'b00xxx110: begin s <= f1; `pc <= `pc + 2; addr <= addr + 1; ld8 <= 1'b1; end // ld r, d8
              8'b00xx1010: // ld A, [r16]
              begin
                ldmem <= 1'b1; s <= f1;
                case (cpu_din[5:4])
                  2'b00: addr <= `bc; 2'b01: addr <= `de;
                  2'b10: begin addr <= `hl; `hl <= `hl+1; end
                  2'b11: begin addr <= `hl; `hl <= `hl-1; end
                endcase
              end
              8'b00xx0010: // ld [r16], A
              begin
                cpu_write <= 1'b1; s <= w1; cpu_dout <= `a;
                case (cpu_din[5:4])
                  2'b00: addr <= `bc; 2'b01: addr <= `de;
                  2'b10: begin addr <= `hl; `hl <= `hl+1; end
                  2'b11: begin addr <= `hl; `hl <= `hl-1; end
                endcase
              end
              8'b00xxx10x: // inc/dec r
                begin
                case (cpu_din[0])
                  1'b0: begin `fn <= 1'b0; `fh <= `dst_reg_l == 4'hf; `fz <= `dst_reg == 8'hff; `dst_reg <= `dst_reg+1; end
                  1'b1: begin `fn <= 1'b1; `fh <= `dst_reg_l == 4'h0; `fz <= `dst_reg == 8'h01; `dst_reg <= `dst_reg-1; end
                  endcase
                end
              // 16-bit alu
              8'h09, 8'h19, 8'h29: begin
                `fc <= ({1'b0,regs[63-cpu_din[7:4]*16-:16]} + {1'b0,`hl}) > {1'b0,16'hffff};
                `fh <= (({5'h0,regs[63-5-cpu_din[7:4]*16-:11]} + {5'h0,regs[26:16]}) > 16'h07ff);
                `fn <= 1'b0; `hl <= regs[63-cpu_din[7:4]*16-:16] + `hl;
              end
              8'h39: begin // sp
                `fc <= ({1'b0,regs[79-:16]} + {1'b0,`hl}) > {1'b0,16'hffff};
                `fh <= (({5'h0,regs[74-:11]} + {5'h0,regs[26:16]}) > 16'h07ff);
                `fn <= 1'b0; `hl <= regs[79-:16] + `hl;
              end
              ////////
              8'b01xxxxxx: begin `dst_reg <= `src_reg; end // ld r, r
              8'b10xxx110: begin s <= f1; addr <= `hl; alu_imm8 <= 1; ldmem <= 1; end // alu (hl)
              8'b10xxxxxx: begin `a <= alu_c[7:0]; `f <= {alu_f[3:0], 4'b0000}; end // alu r
              8'b11xxx110: begin s <= f1; `pc <= `pc + 2; alu_imm8 <= 1'b1; end // alu d8
              8'b11001101, 8'b110xx100: begin s <= f2; `pc <= `pc + 3; call <= 1; end // CALL a16
              8'b11xx0101: // push reg16
              begin
                cpu_write <= 1; s <= w2; addr <= `sp - 2; `sp <= `sp - 2; push <= 1;
                case (cpu_din[5:4])
                  2'b00: {cpu_dout_next, cpu_dout} <= `bc; 2'b01: {cpu_dout_next, cpu_dout} <= `de;
                  2'b10: {cpu_dout_next, cpu_dout} <= `hl; 2'b11: {cpu_dout_next, cpu_dout} <= `af;
                endcase
              end
              8'b00011000: begin `pc <= `pc + 2; s <= f1; jr <= 1; end // JR d8
              8'b001xx000: begin `pc <= `pc + 2; s <= f1; jr <= cc0; end // JR C d8
              8'hd9, // reti
              8'b110xx000,
              8'b11001001: // ret, c9
              begin
                if (cc0 | opcode[0]) begin
                s <= f3; `pc <= addr; addr <= `sp; `sp <= `sp+2;  jp <= 1;
                end else begin ; end
                if (opcode == 8'hd9) begin ei <= 1; end
                cpu_write <= 0;
              end
              8'h27: // daa
              begin
                if (`fc | (~`fn && (`a > 8'h99))) begin `fc = 1; if (`fn) `a = `a - 8'h60; else `a = `a + 8'h60; end
                if (`fh | (~`fn && (`la > 4'h9))) begin if (`fn) `a = `a - 8'h06; else `a = `a + 8'h06; end
                `fz = `a == 0; `fh = 0;
              end
              default: begin $display("%04x: UNK decode 0x%02x", addr, cpu_din); $finish ; end
            endcase
          end // ~halted ?
        end
        w2: begin s <= w1; addr <= addr + 1; cpu_dout <= cpu_dout_next; end                      // state: write 2 B
        w1: begin s <= wa; addr <= `pc; cpu_write <= 0; end                                      // state: write 1 B
        f3: begin s <= f2; addr <= addr + 1; end
        f2: begin s <= f1; addr <= addr + 1; args[7:0] <= args[15:8]; args[15:8] <= cpu_din; end // state: fetch 2 B
        f1:
        begin
          s <= f0; addr <= addr + 1;
          if (cb_mem) begin
            s <= wa; addr <= `hl;
          end else
          if (cb) begin
            last_cb <= cpu_din;
            casex (cpu_din)
            8'bxxxxx110:
            begin cb <= 0; cb_mem <= 1; s <= f1; ldmem <= 1; addr <= `hl; end
            default:
            begin regs[63-cpu_din[2:0]*8-:8] <= cb_alu_out; `f <= {cb_alu_f[3:0], 4'b0000};
            end
            endcase
          end
          if (ld_add_s8 || sp_add_s8) begin `fh <= sp_half_signed_sum[4]; `fc <= sp_carry_signed_sum[8]; `fn <= 0; `fz <= 0; s <= f0; end
          if (ld_add_s8) begin ld_add_s8 <= 0; `hl <= sp_signed_sum; end else
          if (sp_add_s8) begin sp_add_s8 <= 0; `sp <= sp_signed_sum; end else
          if (stsp) begin addr <= `imm16; {cpu_dout_next, cpu_dout} <= `sp; cpu_write <= 1; s <= w2; stsp <= 0; end
          if (ldhl) begin addr <= `hl; cpu_write <= 1; s <= w1; cpu_dout <= cpu_din; ldhl <= 0; end
          if (lda) begin addr <= `pc; ldmem <= 1'b1; s <= wa; end else
          if (lda16) begin addr <= `imm16; ldmem <= 1'b1; s <= f1; lda <= 1; end else
          if (ldah) begin addr <= {8'hff, `imm8}; lda <= 1; ldah <= 0; cpu_write <= 0; s <= f1; end else
          if (stah) begin addr <= {8'hff, `imm8}; cpu_write <= 1; s <= w1; cpu_dout <= `a; end else
          if (sta) begin addr <= `imm16; cpu_write <= 1; s <= w1; cpu_dout <= `a; end else
          if (pop16) begin
            case (reg16)
              0: `bc <= `imm16; 1: `de <= `imm16; 2: `hl <= `imm16;
              3: `af <= {cpu_din, args[15:12], 4'b0000};
              default: ;
            endcase
            addr <= `pc; s <= wa;
          end else
          if (call) begin
            if (cc) begin
              {cpu_dout_next, cpu_dout} <= addr; cpu_write <= 1; s <= w2; addr <= `sp - 2;
              `pc <= `imm16; `sp <= `sp - 2;
            end else begin
              s <= f0; addr <= addr + 1; call <= 0;
            end
          end else
          if (ldmem) begin addr <= `pc; s<=wa; end else
          if (alu_imm8)  begin alu_imm8 <= 0; `a <= alu_c[7:0]; `f <= {alu_f[3:0], 4'b0000}; end else
          if (ld8) begin `dst_reg <= `imm8; end else
          if (ld16) begin
            case (reg16)
              0: `bc <= `imm16; 1: `de <= `imm16; 2: `hl <= `imm16; 3: `sp <= `imm16;
              default: ;
            endcase
            ld16 <= 0;
          end else if (jr) begin
              addr <= cpu_din[7] ? (`pc - {1'b0, ~cpu_din[6:0]} - 1'b1) : (`pc + cpu_din[7:0]);
             `pc <= cpu_din[7] ? (`pc - {1'b0, ~cpu_din[6:0]} - 1'b1) : (`pc + cpu_din[7:0]);
              s <= wa; jp <= 0;
          end else if (jp) begin addr <= `imm16; `pc <= `imm16; s <= wa; jp <= 0; end
          args[7:0] <= args[15:8]; args[15:8] <= cpu_din;
        end

        wa: begin s <= f0; addr <= addr+1; // state: wait
        if (ldmem) begin
          if (cb_mem) begin
            cb_mem <= 0; cpu_write <= 1; s<=w1; addr <= `hl; cpu_dout <= cb_alu_out;
            `f <= {cb_alu_f[3:0], 4'b0000};
          end else
          if (op_hl_inc) begin
            cpu_write <= 1; s<=w1; addr <= `hl; cpu_dout <= (cpu_din + 1);
            `fn <= 1'b0; `fh <= cpu_din[3:0] == 4'hf; `fz <= cpu_din == 8'hff;
          end else
          if (op_hl_dec) begin
            cpu_write <= 1; s<=w1; cpu_dout <= (cpu_din - 1);
            `fn <= 1'b1; `fh <= cpu_din[3:0] == 4'h0; addr <= `hl; `fz <= cpu_din == 8'h01;
          end else
          if (alu_imm8)  begin alu_imm8 <= 0; `a <= alu_c[7:0]; `f <= {alu_f[3:0], 4'b0000}; end else
          if (ld8) `dst_reg <= cpu_din; else `a <= cpu_din; ldmem <= 0; end  end
        default: ;
      endcase
    end
  end

endmodule
