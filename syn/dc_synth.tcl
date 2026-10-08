# ==============================================================================
# Design Compiler Synthesis Script : APB Interface with Master SPI Core
# Top module : spi_core        Library : lsi_10k
# Run from this folder:  dc_shell -f dc_synth.tcl | tee dc_synth.log
# ==============================================================================

# 1. Clear memory
remove_design -all

# 2. Libraries
set search_path ". ../rtl /home/cad/eda/SYNOPSYS/Design_compiler/syn/X-2025.06/libraries/syn"
set target_library {lsi_10k.db}
set link_library   "* lsi_10k.db"

# 3. Read & elaborate the RTL (apb_spi_defines.vh is found through search_path)
analyze -format verilog {apb_slave.v baud_generator.v spi_slave_select.v shifter.v spi_core.v}
elaborate spi_core

# 4. Set top and link
current_design spi_core
link

# 5. Check design
check_design > spi_check_design.rpt

# 6. Timing constraints : 20 ns PCLK (50 MHz)
create_clock -name PCLK -period 20 [get_ports PCLK]
set_input_delay  2.0 -clock PCLK [remove_from_collection [all_inputs] [get_ports {PCLK PRESETn}]]
set_output_delay 2.0 -clock PCLK [all_outputs]
set_false_path -from [get_ports PRESETn]

# 7. Synthesize
compile_ultra

# 8. Reports
report_area -hierarchy              > spi_area.rpt
report_timing -max_paths 10         > spi_timing.rpt
report_power                        > spi_power.rpt
report_qor                          > spi_qor.rpt
report_constraint -all_violators    > spi_violations.rpt
report_reference -hierarchy         > spi_cells.rpt

# 9. Netlist and constraints
write_file -f verilog -hier -output spi_core_netlist.v
write_sdc spi_core.sdc
