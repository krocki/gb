
puts [llength $argv]
foreach i $argv {puts $i}
puts [lindex $argv 0]

set OUT_NAME [lindex $argv 0]

open_hw
connect_hw_server
open_hw_target

current_hw_device [get_hw_devices xc7z020_1]
set_property PROGRAM.FILE $OUT_NAME.bit [get_hw_devices xc7z020_1]

program_hw_devices [get_hw_devices xc7z020_1]
