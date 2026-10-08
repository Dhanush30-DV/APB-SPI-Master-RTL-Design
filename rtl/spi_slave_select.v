//==============================================================================================
// File        : spi_slave_select.v
// Module      : spi_slave_select
// Project     : APB Interface with Master SPI Core - RTL Design
// Author      : Dhanush
// Language    : Verilog-2001
// Description :
//   Slave-select and transfer-timing control.
//   - Drives SS low for one 8-bit transfer when the master sends data
//   - Generates receive_data at the end of the transfer and the TIP flag
//==============================================================================================

`timescale 1ns/10ps
`include "apb_spi_defines.vh"

module spi_slave_select(input PRESETn,
                         input [1:0] spi_mode,
                         input mstr,
                         input spiswai,
                         input PCLK,
                         input send_data,
                         input [11:0] BaudRateDivisor,
                         output reg ss,
                         output reg receive_data,
                         output tip);

 reg[15:0] count;
 wire [15:0] target;
 reg rcv;

 // Transfer length: 16 baud periods = 8 SCLK cycles = 8 bits
 assign target = {BaudRateDivisor, 4'b0000};   // BaudRateDivisor * 16
 // Transfer in progress while SS is asserted (active low)
 assign tip = (~ss);

 always@(negedge PRESETn or posedge PCLK)
   begin
     if(!PRESETn)
       begin
         count<=16'hffff;
         ss<=1'b1;
         rcv<=1'b0;
       end
     else if(mstr && (spi_mode == 2'b00 || (spi_mode == 2'b01 && (~spiswai))))
       begin
         if(send_data)
           begin
             ss <= 1'b0;
             count<= 16'h0;
           end
         else if(count <= (target-16'd1))
           begin
             ss<=1'b0;
             count <= count + 16'd1;
             if(count==(target-16'd1))
               rcv<=1'b1;
           end
         else
           begin
             ss <= 1'b1;
             rcv<=1'b0;
             count <= 16'hffff;
           end
       end
     else
       begin
         ss<=1'b1;
         rcv<=1'b0;
         count <= 16'hffff;
       end
   end

 // Registered receive strobe at end of transfer
 always@(posedge PCLK or negedge PRESETn)
   begin
     if(!PRESETn)
       receive_data <= 1'b0;
     else
       receive_data <= rcv;
   end

endmodule
