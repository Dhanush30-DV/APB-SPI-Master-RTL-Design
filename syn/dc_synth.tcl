##=============================================================================
## Synopsys Design Compiler script for spi_core
## Run from this folder:  dc_shell -f dc_synth.tcl | tee dc_synth.log
## Edit TARGET_LIB to point to your standard-cell library (.db) on the server.
##=============================================================================
set TARGET_LIB "<path_to_your_library>/your_std_cell_lib.db"

set_app_var search_path   ". ../rtl $search_path"
set_app_var target_library $TARGET_LIB
set_app_var link_library  "* $TARGET_LIB"

file mkdir reports
file mkdir outputs

## Read and elaborate
analyze -format verilog {apb_slave.v baud_generator.v spi_slave_select.v shifter.v spi_core.v}
elaborate spi_core
current_design spi_core
link
check_design > reports/check_design.rpt

## Constraints: 100 MHz PCLK
create_clock -name PCLK -period 10 [get_ports PCLK]
set_input_delay  2 -clock PCLK [remove_from_collection [all_inputs] [get_ports {PCLK PRESETn}]]
set_output_delay 2 -clock PCLK [all_outputs]
set_false_path -from [get_ports PRESETn]

## Synthesize
compile

## Reports
report_qor               > reports/qor.rpt
report_area -hierarchy   > reports/area.rpt
report_timing -max_paths 10 > reports/timing.rpt
report_power             > reports/power.rpt
report_reference -hierarchy > reports/cells.rpt

## Netlist and constraints
write -format verilog -hierarchy -output outputs/spi_core_netlist.v
write_sdc outputs/spi_core.sdc

## To view the schematic:  start_gui   (then Schematic -> New Schematic View)
