//==============================================================================================
// File        : shifter.v
// Module      : shifter
// Project     : APB Interface with Master SPI Core - RTL Design
// Author      : Dhanush
// Language    : Verilog-2001
// Description :
//   Full-duplex shift-register datapath.
//   - Shifts transmit data out on MOSI and captures MISO into a receive register
//   - LSB-first or MSB-first, selected by LSBFE
//   - Shift/sample timing driven by the baud generator for the selected SPI mode
//==============================================================================================

`timescale 1ns/10ps
`include "apb_spi_defines.vh"

module shifter(input PCLK,
               input PRESETn,
               input ss,
               input send_data,
               input lsbfe,
               input cpha,
               input cpol,
               input flag_low,
               input flag_high,
               input flags_low,
               input flags_high,
               input [`APB_DATA_WIDTH-1:0] data_mosi,
               input miso,
               input receive_data,
               output [`APB_DATA_WIDTH-1:0] data_miso,
               output reg mosi);

 reg [`APB_DATA_WIDTH-1:0] shift_register;
 reg [`APB_DATA_WIDTH-1:0] temp_reg;

 reg [2:0] count;
 reg [2:0] count1;
 reg [2:0] count2;
 reg [2:0] count3;

 // ---------------- Load transmit data ----------------
 always@(posedge PCLK or negedge PRESETn)
   begin
     if(!PRESETn)
       begin
         shift_register <= 8'b0;
       end
     else if(send_data)
       begin
         shift_register <= data_mosi;
       end
   end

 // Received byte is presented to the APB block when receive_data is high
 assign data_miso=receive_data?temp_reg:8'b0000_0000;

 // ---------------- MOSI: transmit, LSB-first or MSB-first ----------------
 always@(posedge PCLK or negedge PRESETn)
   begin
     if(!PRESETn)
       begin
         mosi <= 1'b0;
         count <= 3'd0;
         count1 <= 3'd7;
       end
     else
       begin
         if(!ss)
           begin
             if((!cpha && cpol)||(cpha && !cpol))
               begin
                 if(lsbfe)
                   begin
                     if(count <= 3'd7)
                       begin
                         if(flags_high)
                           begin
                             mosi<= shift_register[count];
                             count <= count + 1'b1;
                           end
                       end
                     else
                       count <= 3'd0;
                   end
                 else
                   begin
                     if(count1 >= 3'd0)
                       begin
                         if(flags_high)
                           begin
                             mosi<= shift_register[count1];
                             count1 <= count1 -1'b1;
                           end
                       end
                     else
                       count1 <= 3'd7;
                   end
               end
             else
               begin
                 if(lsbfe)
                   begin
                     if(count <= 3'd7)
                       begin
                         if(flags_low)
                           begin
                             mosi<= shift_register[count];
                             count <= count + 1'b1;
                           end
                       end
                     else
                       count <= 3'd0;
                   end
                 else
                   begin
                     if(count1 >= 3'd0)
                       begin
                         if(flags_low)
                           begin
                             mosi<= shift_register[count1];
                             count1 <= count1- 1'b1;
                           end
                       end
                     else
                       count1 <= 3'd7;
                   end
               end
           end
        end
   end

 // ---------------- MISO: receive, LSB-first or MSB-first ----------------
 always@(posedge PCLK or negedge PRESETn)
   begin
     if(!PRESETn)
       begin
         count2 <= 3'd0;
         count3 <= 3'd7;
         temp_reg<= 8'b0;
       end
     else
       begin
         if(!ss)
           begin
             if((!cpha && cpol)||(cpha && !cpol))
               begin
                 if(lsbfe)
                   begin
                     if(count2 <= 3'd7)
                       begin
                         if(flag_high)
                           begin
                             temp_reg[count2] <= miso;
                             count2 <= count2 + 1'b1;
                           end
                       end
                     else
                       count2 <= 3'd0;
                   end
                 else
                   begin
                     if(count3 >= 3'd0)
                       begin
                         if(flag_high)
                           begin
                             temp_reg[count3] <= miso;
                             count3 <= count3 -1'b1;
                           end
                       end
                     else
                       count3 <= 3'd7;
                   end
               end
             else
               begin
                 if(lsbfe)
                   begin
                     if(count2 <= 3'd7)
                       begin
                         if(flag_low)
                           begin
                             temp_reg[count2] <= miso;
                             count2 <= count2 + 1'b1;
                           end
                       end
                     else
                       count2 <= 3'd0;
                   end
                 else
                   begin
                     if(count3 >= 3'd0)
                       begin
                         if(flag_low)
                           begin
                             temp_reg[count3] <= miso;
                             count3 <= count3- 1'b1;
                           end
                       end
                     else
                       count3 <= 3'd7;
                   end
               end
           end
       end
   end
endmodule
