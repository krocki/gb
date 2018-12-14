`timescale 1 ns / 1 ps

//`define fname "07.hex"

module gbtest;
  parameter romfile = `fname;
  parameter logfile = `log_fname;
  parameter USE_BOOTROM = 0;
  reg clk = 1;
  reg resetn = 0;
  reg[31:0] cycles = 0;

  always #5 clk = ~clk;

  initial begin
    repeat (1) @(posedge clk); resetn <= 1;
    repeat (10000000) @(posedge clk); $finish;
  end

  wire [7:0] cpu_din;
  wire cpu_write;
  wire[7:0] cpu_dout;
  wire[7:0] last_op;
  wire[15:0] cpu_addr;
  integer f;

  initial begin
    f = $fopen("out.txt");
  end

  wire[7:0] iack, iflags;

  mmu #(.romfile(romfile), .BOOTROM_EN(USE_BOOTROM)) mmu0(.clk(clk), .resetn(resetn), .data_in(cpu_dout), .data(cpu_din), .addr(cpu_addr), .we(cpu_write), .iflags(iflags), .iack(iack));

  gbcpu #(.logfile(logfile), .BOOTROM_EN(USE_BOOTROM))
  gbcpu_inst (
   .clk(clk),
   .resetn(resetn),
   .cpu_din(cpu_din),
   .cpu_dout(cpu_dout),
   .addr(cpu_addr),
   .cpu_write(cpu_write),
   .cpu_op(last_op),
   .iflags(iflags),
   .iack(iack)
  );

endmodule
