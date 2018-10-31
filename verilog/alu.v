`timescale 1 ns / 1 ps

// CB prefix alu (bitwise ops)
module cb_alu(op,in,out,in_f,f);
  input [4:0] op; input [7:0] in; input[3:0] in_f;
  output reg [7:0] out; output reg [3:0] f;

  `define fc in_f[0]
  `define o_fc f[0]
  always @(*)
  begin

    casex(op)
      5'b01xxx: // bit
      begin out = in; f = {~in[op[2:0]], 2'b01, `fc}; end
      5'b1xxxx: // clr, set
      begin out = in; out[op[2:0]] = op[3]; f = in_f; end
      5'b000x0: // rlc, rl
      begin `o_fc = in[7]; out = {in[6:0], op[1] ? `fc : in[7]}; f[3:1] = {out == 0, 2'b0}; end
      5'b001x1: // srl, sra
      begin `o_fc = in[0]; out = {op[1] ? 1'b0 : in[7], in[7:1]}; f[3:1] = {out == 0, 2'b0}; end
      5'b000x1: // rr, rrc
      begin `o_fc = in[0]; out = {op[1] ? `fc : in[0], in[7:1]}; f[3:1] = {out == 0, 2'b0}; end
      5'b00100: // sla
      begin `o_fc = in[7]; out = {in[6:0], 1'b0}; f[3:1] = {out == 0, 2'b0};end
      5'b00110: // swap
      begin `o_fc = 0; out = {in[3:0], in[7:4]}; f[3:1] = {out == 0, 2'b0};end
      default: ;
    endcase
  end

endmodule

// 'main' ALU
module alu (op,a,b,in_f,c,f);

  input [2:0] op; input [7:0] a; input [7:0] b;
  input [3:0] in_f;
  output [7:0] c; output [3:0] f;
  reg[7:0] dummy;
  reg[7:0] c; reg[3:0] f;

  reg[3:0] h; // 4-bit result

  always @(*)
  begin
    case (op)
      3'b000, 3'b001: begin // add, adc
        {f[1], h} = {4'b0000, op[0] & in_f[0]} + {1'b0, a[3:0]} + {1'b0, b[3:0]};
        {f[0], c} = {8'h00, op[0] & in_f[0]} + {1'b0, a} + {1'b0, b};
        f[3] = (c == 0); f[2] = 0;
      end
      3'b010, 3'b011: begin // sub, sbc
        {f[1], h} = {1'b0, a[3:0]} - {1'b0, b[3:0]} - {4'h0, op[0] & in_f[0]};
        {f[0], c} = {1'b0, a} - {1'b0, b} - {8'h00, op[0] & in_f[0]};
        f[3] = (c == 0); f[2] = 1;
      end // sbc
      3'b100: begin c = a & b; f = {c == 0, 3'b010}; end // and
      3'b101: begin c = a ^ b; f = {c == 0, 3'b000}; end // xor
      3'b110: begin c = a | b; f = {c == 0, 3'b000}; end // or
      3'b111: begin // cp
        {f[1], h} = {1'b0, a[3:0]} - {1'b0, b[3:0]};
        {f[0], dummy} = {1'b0, a} - {1'b0, b};
        f[3] = dummy == 0; f[2] = 1; c = a;
      end
    endcase
  end
endmodule
