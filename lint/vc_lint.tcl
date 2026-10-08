# ==============================================================================
# Synopsys VC SpyGlass lint (VC Static X-2025.06) for spi_core
# Run:  make lint        (Makefile in this folder)
# The run used the RTL modules from ../rtl concatenated into ./rtl/apb_spi_core_all.v
# ==============================================================================

# Setup Search Path
set search_path "./ ../rtl"
set link_library " "

# Enable VC Static Linting Engine
set_app_var enable_lint true

# Set Linting Goal
configure_lint_setup -goal lint_rtl

# Analyze & Elaborate Design
analyze -verbose -format verilog "./rtl/apb_spi_core_all.v"
elaborate spi_core

# Perform Lint Checks
check_lint

# Generate Linting Report
report_lint -verbose -file report_lint.txt
