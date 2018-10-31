set partname xc7z020clg400-1
set TOP top
set opt quick

puts [llength $argv]
foreach i $argv {puts $i}
puts [lindex $argv 0]
set OUT_NAME [lindex $argv 0]

## src
read_verilog top_pynq.v
read_verilog framebuffer.v
read_verilog rams.v
read_verilog vram.v
read_verilog lcd.v
read_verilog ppu.v
read_verilog mmu.v
read_verilog cpu.v
read_verilog alu.v
read_verilog timer.v

read_vhdl xess_btns.vhd
read_vhdl xess_sseg.vhd
read_vhdl dvid.vhd
read_vhdl dvid_test.vhd
read_vhdl TMDS_encoder.vhd

read_checkpoint clocking.dcp

read_xdc pynq-z1.xdc

#opt3
#synth_design -flatten_hierarchy full -part $partname -top $TOP
#opt_design -sweep -remap -propconst
#opt_design -directive Explore
#place_design -directive Explore
#phys_opt_design -retime -rewire -critical_pin_opt -placement_opt -critical_cell_opt
#route_design -directive Explore
#place_design -post_place_opt
#phys_opt_design -retime
#route_design -directive NoTimingRelaxation

#opt2
#opt_design -sweep -propconst -resynth_seq_area
#opt_design -directive ExploreSequentialArea
#opt_design -resynth_seq_area

#opt1
#synth_design -part $partname -top top
#synth_design -retiming -part $partname -top $TOP
#opt_design -propconst
#place_design -directive Explore
#phys_opt_design -retime -rewire
#route_design -directive NoTimingRelaxation

synth_design -part $partname -top $TOP -verilog_define "ROM=\"$OUT_NAME.hex\""
place_design
#phys_opt_design -retime -rewire
route_design

#synth_design -part $partname -top $TOP -effort_level $opt
#place_design -directive Quick
#route_design -directive Quick

report_utilization
report_timing

write_bitstream -force $OUT_NAME.bit
