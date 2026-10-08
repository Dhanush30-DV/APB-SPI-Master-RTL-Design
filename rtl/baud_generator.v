//==============================================================================================
// File        : baud_generator.v
// Module      : baud_generator
// Project     : APB Interface with Master SPI Core - RTL Design
// Author      : Dhanush
// Language    : Verilog-2001
// Description :
//   Programmable baud-rate generator.
//   - Divides PCLK by (SPPR+1)*2^(SPR+1) to produce SCLK
//   - SCLK idle level set by CPOL; runs only while SS is low
//   - Generates sample (flag_*) and shift (flags_*) strobes for all four
//     SPI modes (CPOL/CPHA)
//==============================================================================================

`timescale 1ns/10ps
`include "apb_spi_defines.vh"

module baud_generator(input PCLK,
                       input PRESETn,
                       input [1:0] spi_mode,
                       input spiswai,
                       input [2:0] sppr,
                       input [2:0] spr,
                       input cpol,
                       input cpha,
                       input ss,
                       output reg sclk,
                       output reg flag_low,
                       output reg flag_high,
                       output reg flags_low,
                       output reg flags_high,
                       output  [11:0]BaudRateDivisor);

 wire pre_sclk;
 reg[11:0] count;

 // Baud-rate divisor = (SPPR + 1) * 2^(SPR + 1)
 assign BaudRateDivisor = ({9'd0, sppr} + 12'd1) << ({1'b0, spr} + 4'd1);

 // Idle level of SCLK follows clock polarity (CPOL)
 assign pre_sclk=cpol? 1'b1 : 1'b0;

 // ---------------- SCLK generation ----------------
 always@(posedge PCLK or negedge PRESETn)
   begin
     if(!PRESETn)
       begin
         count<=12'b0;
         sclk<=1'b0;      // constant reset value: CPOL is 0 while in reset (SPI_CR_1 resets to 8'h04)
       end
     else if((~ss) && (spi_mode == 2'b00 || (spi_mode == 2'b01 && (~spiswai))) )
       begin
         if(count==(BaudRateDivisor-12'd1))
           begin
             count<=12'b0;
             sclk<=~sclk;
           end
         else
           count <= count+12'd1;
       end
     else
       begin
         sclk <= pre_sclk;
         count<=12'b0;
       end
   end

 // ---------------- Sample flags (receive edge, per CPOL/CPHA) ----------------
 always@(posedge PCLK or negedge PRESETn)
   begin
     if(!PRESETn)
       begin
         flag_low <= 1'b0;
         flag_high <= 1'b0;
       end
     else
       begin
         if((!cpha && cpol)||(cpha && !cpol))
           begin
             if(sclk)
               if(count == (BaudRateDivisor-12'd1))
                 flag_high<= 1'b1;
               else
                 flag_high <= 1'b0;
             else
               flag_high <= 1'b0;
           end
         else
           begin
             if(~sclk)
               if(count == (BaudRateDivisor-12'd1))
                 flag_low<= 1'b1;
               else
                 flag_low <= 1'b0;
             else
               flag_low<= 1'b0;
           end
       end
   end

 // ---------------- Shift flags (transmit edge, one PCLK earlier) ----------------
 always@(posedge PCLK or negedge PRESETn)
   begin
     if(!PRESETn)
       begin
         flags_low <= 1'b0;
         flags_high <= 1'b0;
       end
     else
       begin
         if((!cpha && cpol)||(cpha && !cpol))
           begin
             if(sclk)
               if(count == (BaudRateDivisor-12'd2))
                 flags_high<= 1'b1;
               else
                 flags_high <= 1'b0;
             else
               flags_high <= 1'b0;
           end
         else
           begin
             if(~sclk)
               if(count == (BaudRateDivisor-12'd2))
                 flags_low<= 1'b1;
               else
                 flags_low <= 1'b0;
             else
               flags_low<= 1'b0;
           end
       end
   end
endmodule
