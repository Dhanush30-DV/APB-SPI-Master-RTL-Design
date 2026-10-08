# Lint — Synopsys VC SpyGlass

**Tool:** Synopsys VC Static (VC SpyGlass) X-2025.06 · **Goal:** `lint_rtl` · **Top:** `spi_core`

## Result

| Severity | Count |
|---|---|
| **Fatal** | **0** |
| **Error** | **0** |
| Warning | 1 (tool setup, not RTL) |
| Info | 11 |

Elaboration summary from the run:

| Item | Value |
|---|---|
| Flip-flops (bitwise) | 110 |
| **Latches (bitwise)** | **0** |
| Black-box instances | 0 |
| Elaboration errors / warnings | 0 / 0 |

## Message review

| Tag | Count | Explanation |
|---|---|---|
| `DB_CANT_LOAD` (warning) | 1 | Comes from the empty `link_library` setting in the script. RTL lint does not need a cell library, so this is a setup message, not a design issue. |
| `RegInputOutput-ML` (info) | 10 | Some top-level ports are not registered: `PSEL`, `PENABLE`, `PWRITE`, `PADDR`, `PWDATA`, `miso`, `PREADY`, `PSLVERR`, `PRDATA`, `spi_interrupt_request`. This is expected for an AMBA APB slave. APB requires `PREADY` and `PRDATA` in the same access phase, so they are decoded combinationally from the APB FSM state and the registers. |
| `ReportPortInfo-ML` (info) | 1 | The tool generated a port-information report. |

**No coding violations:** no latches, no multiple drivers, no width mismatches and no unreachable code.

## Files

| File | Description |
|---|---|
| [`vc_lint.tcl`](vc_lint.tcl) | VC SpyGlass lint script |
| [`Makefile`](Makefile) | `make lint` runs the script, `make clean` removes outputs |
| [`reports/report_lint.txt`](reports/report_lint.txt) | Full lint report |
| [`reports/vc_lint_run.log`](reports/vc_lint_run.log) | Console log of the run |

For the run, the five modules in [`../rtl`](../rtl) were combined into a single file, `rtl/apb_spi_core_all.v`. The code is identical. The file and line numbers in the report refer to that combined file.
