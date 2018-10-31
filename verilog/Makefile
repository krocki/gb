all: cpu_tests
games: gb_mario
cpu_tests: gb_01 gb_11

VIVADO_BIN=~/opt/Xilinx/Vivado/2018.2/bin/vivado

gb_%:
	${VIVADO_BIN} -mode batch -source build.tcl -tclargs $*
	rm -rf *.html *.xml *.log *.jou *webtalk* fsm_encoding*

prog_%:
	${VIVADO_BIN} -mode batch -source prog.tcl -tclargs $*

clean:
	rm -rf *.bit *.jou
