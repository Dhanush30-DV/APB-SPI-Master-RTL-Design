//==============================================================================================
// File        : spi_core.v
// Module      : spi_core (top level)
// Project     : APB Interface with Master SPI Core - RTL Design
// Author      : Dhanush
// Language    : Verilog-2001
// Description :
//   Top level of the APB-to-SPI master core. Connects:
//   - apb_slave        : APB interface, registers, mode FSM, interrupt
//   - baud_generator   : SCLK generation and shift/sample strobes
//   - spi_slave_select : SS control and transfer timing
//   - shifter          : MOSI/MISO shift-register datapath
//==============================================================================================

`timescale 1ns/10ps
`include "apb_spi_defines.vh"

module spi_core(input PCLK,
                 input PRESETn,
                 input [`APB_ADDR_WIDTH-1:0] PADDR,
                 input PWRITE,
                 input PSEL,
                 input PENABLE,
                 input [`APB_DATA_WIDTH-1:0] PWDATA,
                 output [`APB_DATA_WIDTH-1:0] PRDATA,
                 output PREADY,
                 output PSLVERR,
                 input miso,
                 output ss,
                 output sclk,
                 output spi_interrupt_request,
                 output mosi);

 wire [`APB_DATA_WIDTH-1:0] miso_data;
 wire [`APB_DATA_WIDTH-1:0] mosi_data;

 wire send_data;
 wire receive_data;
 wire tip;
 wire [1:0] spi_mode;

 wire mstr;
 wire cpol;
 wire cpha;
 wire lsbfe;
 wire spiswai;
 wire [2:0] sppr;
 wire [2:0] spr;
 wire [11:0] BaudRateDivisor;
 wire flag_high;
 wire flag_low;
 wire flags_low;
 wire flags_high;

 apb_slave APB_INTERFACE(.PCLK(PCLK), .PRESETn(PRESETn), .PADDR(PADDR), .PWRITE(PWRITE),
                         .PSEL(PSEL), .PENABLE(PENABLE), .PWDATA(PWDATA), .PRDATA(PRDATA),
                         .PREADY(PREADY), .PSLVERR(PSLVERR), .ss(ss), .miso_data(miso_data),
                         .send_data(send_data), .receive_data(receive_data), .tip(tip),
                         .mosi_data(mosi_data), .spi_mode(spi_mode), .mstr(mstr), .cpol(cpol),
                         .cpha(cpha), .lsbfe(lsbfe), .spiswai(spiswai), .sppr(sppr), .spr(spr),
                         .spi_interrupt_request(spi_interrupt_request));

 baud_generator BAUD_GEN(.PCLK(PCLK), .PRESETn(PRESETn), .spi_mode(spi_mode), .spiswai(spiswai),
                         .sppr(sppr), .spr(spr), .ss(ss), .cpol(cpol), .cpha(cpha), .flag_high(flag_high),
                         .flag_low(flag_low), .flags_low(flags_low), .flags_high(flags_high), .sclk(sclk),
                         .BaudRateDivisor(BaudRateDivisor));

 spi_slave_select SLAVE_SELECT(.PCLK(PCLK), .PRESETn(PRESETn), .spi_mode(spi_mode), .mstr(mstr),
                               .spiswai(spiswai), .send_data(send_data), .BaudRateDivisor(BaudRateDivisor),
                               .ss(ss), .receive_data(receive_data), .tip(tip));

 shifter SHIFTER(.PCLK(PCLK), .PRESETn(PRESETn), .ss(ss), .send_data(send_data),
                 .lsbfe(lsbfe), .cpha(cpha), .cpol(cpol), .data_mosi(mosi_data), .miso(miso),
                 .flag_low(flag_low), .flag_high(flag_high), .flags_low(flags_low),
                 .flags_high(flags_high), .receive_data(receive_data), .data_miso(miso_data), .mosi(mosi));
endmodule
