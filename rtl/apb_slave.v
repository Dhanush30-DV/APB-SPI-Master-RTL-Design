//==============================================================================================
// File        : apb_slave.v
// Module      : apb_slave
// Project     : APB Interface with Master SPI Core - RTL Design
// Author      : Dhanush
// Language    : Verilog-2001
// Description :
//   APB slave interface and register block of the SPI master core.
//   - 3-state APB FSM (IDLE/SETUP/ENABLE) generating PREADY and PSLVERR
//   - Control (CR1, CR2), baud-rate (BR), status (SR) and data (DR) registers
//   - SPI mode FSM (RUN/WAIT/STOP) and interrupt-request generation
//   - Hands transmit data to the shifter and captures received data
//==============================================================================================

`timescale 1ns/10ps
`include "apb_spi_defines.vh"

module apb_slave(input PCLK,
                 input PRESETn,
                 input [`APB_ADDR_WIDTH-1:0] PADDR,
                 input PWRITE,
                 input PSEL,
                 input PENABLE,
                 input [`APB_DATA_WIDTH-1:0] PWDATA,
                 output  [`APB_DATA_WIDTH-1:0] PRDATA,
                 output  PREADY,
                 output  PSLVERR,
                 input ss,
                 input [`APB_DATA_WIDTH-1:0] miso_data,
                 output reg send_data,
                 input receive_data,
                 input tip,
                 output reg [`APB_DATA_WIDTH-1:0]mosi_data,
                 output reg [1:0] spi_mode,
                 output  mstr,
                 output  cpol,
                 output  cpha,
                 output  lsbfe,
                 output  spiswai,
                 output  [2:0] sppr,
                 output  [2:0] spr,
                 output  spi_interrupt_request);

// ---------------- APB FSM states ----------------
localparam IDLE =2'b00;
localparam SETUP =2'b01;
localparam ENABLE =2'b10;

// ---------------- SPI operating modes ----------------
localparam spi_run =2'b00;
localparam spi_wait=2'b01;
localparam spi_stop=2'b10;

// Write masks: reserved bits of CR2 and BR always read back as 0
localparam cr2_mask = 8'b0001_1011;
localparam br_mask = 8'b0111_0111;

reg[1:0] STATE, next_state;
reg[1:0] next_mode;

wire spie;
wire sptie;
wire spe;

wire modf;
wire ssoe;
wire modfen;

wire sptef;
wire spif;

wire wr_enb;
wire rd_enb;

// ---------------- Memory-mapped registers ----------------
// PADDR 3'b000 : SPI_CR_1  (SPIE, SPE, SPTIE, MSTR, CPOL, CPHA, SSOE, LSBFE)
// PADDR 3'b001 : SPI_CR_2  (MODFEN, SPISWAI)
// PADDR 3'b010 : SPI_BR    (SPPR[6:4], SPR[2:0])
// PADDR 3'b011 : SPI_SR    (SPIF, SPTEF, MODF) - read only
// PADDR 3'b101 : SPI_DR    (data register)
reg [7:0] SPI_CR_1;
reg [7:0] SPI_CR_2;
reg [7:0] SPI_BR;
wire [7:0] SPI_SR;
reg [7:0] SPI_DR;

 // ---------------- APB FSM: IDLE -> SETUP -> ENABLE ----------------
 always@(posedge PCLK or negedge PRESETn)
   begin
     if(!PRESETn)
         STATE <= IDLE;
     else
         STATE <= next_state;
   end

 always@(*)
   begin
     case(STATE)
          IDLE  : begin
                    if(PSEL && !PENABLE)
                      next_state = SETUP;
                    else
                      next_state = IDLE;
                  end

          SETUP : begin
                    if(PSEL && PENABLE)
                      next_state = ENABLE;
                    else if(PSEL && !PENABLE)
                      next_state = SETUP;
                    else
                      next_state = IDLE;
                  end

          ENABLE: begin
                    if(PSEL)
                      next_state = SETUP;
                    else
                      next_state = IDLE;
                  end

          default: next_state = IDLE;
     endcase
   end

 // PREADY asserted in the ENABLE (access) phase; PSLVERR flags an access during a transfer
 assign PREADY = (STATE==ENABLE)?1'b1:1'b0;
 assign PSLVERR = (STATE==ENABLE)?tip:1'b0;

 assign wr_enb = PWRITE && (STATE == ENABLE);
 assign rd_enb = !PWRITE && (STATE == ENABLE);

 // ---------------- Register write / SPI data hand-off ----------------
 always @(posedge PCLK or negedge PRESETn)
   begin
     if (!PRESETn)
       begin
         SPI_CR_1 <= 8'b0000_0100;
         SPI_CR_2 <= 8'b0000_0000;
         SPI_BR <= 8'b0000_0000;
         SPI_DR <= 8'b0000_0000;
         send_data <= 1'b0;
         mosi_data <= 8'b0000_0000;
       end
     else if (wr_enb)
       begin
         case (PADDR)
               3'b000: SPI_CR_1 <= PWDATA;
               3'b001: SPI_CR_2 <= (PWDATA & cr2_mask);
               3'b010: SPI_BR <= (PWDATA & br_mask);
               3'b101: SPI_DR <= PWDATA;
               default:SPI_DR <= PWDATA ;
         endcase
       end
     else if (((SPI_DR == PWDATA) && (SPI_DR != miso_data)) && (spi_mode == spi_run || spi_mode == spi_wait))
       begin
         send_data <= 1'b1;
         mosi_data <= SPI_DR;
         SPI_DR <= 8'b0;
       end
     else if((receive_data)&&(spi_mode == spi_run || spi_mode == spi_wait))
       begin
         SPI_DR<= miso_data;
         send_data <= 1'b0;
       end
     else
       begin
         send_data <= 1'b0;
       end
   end

 // ---------------- Register read-back (full address decode) ----------------
 assign PRDATA = rd_enb ?
               (PADDR == 3'b000 ? SPI_CR_1 :
               (PADDR == 3'b001 ? SPI_CR_2 :
               (PADDR == 3'b010 ? SPI_BR :
               (PADDR == 3'b011 ? SPI_SR : SPI_DR))))
               : 8'b0;

 // ---------------- Control-bit decode ----------------
 assign mstr = SPI_CR_1[4];
 assign cpol = SPI_CR_1[3];
 assign cpha = SPI_CR_1[2];
 assign ssoe = SPI_CR_1[1];
 assign lsbfe = SPI_CR_1[0];
 assign spie = SPI_CR_1[7];
 assign spe = SPI_CR_1[6];
 assign sptie = SPI_CR_1[5];

 assign modfen = SPI_CR_2[4];
 assign spiswai = SPI_CR_2[1];

 assign sppr = SPI_BR[6:4];
 assign spr = SPI_BR[2:0];

 // Mode-fault detection
 assign modf=((~ss)&& mstr && modfen && (~ssoe));

 // Interrupt request from SPIF / SPTEF / MODF, gated by SPIE and SPTIE
 assign spi_interrupt_request = ( !spie && !sptie )? 1'b0 :
                                ( spie && !sptie )? (spif || modf ):
                                ( !spie && sptie )? sptef :
                                (spif || sptef || modf );

 // ---------------- SPI mode FSM: RUN / WAIT / STOP ----------------
 always@(posedge PCLK or negedge PRESETn)
   begin
     if(!PRESETn)
       spi_mode <= spi_run;
     else
       spi_mode <= next_mode;
   end

 always@(*)
   begin
     case(spi_mode)
          spi_run:  begin
                      if(!spe)
                        next_mode = spi_wait;
                      else
                        next_mode = spi_run;
                    end

          spi_wait: begin
                      if(spe)
                        next_mode = spi_run;
                      else if(spiswai)
                        next_mode = spi_stop;
                      else
                        next_mode = spi_wait;
                    end

          spi_stop: begin
                      if(spe)
                        next_mode = spi_run;
                      else if(!spiswai)
                        next_mode = spi_wait;
                      else
                        next_mode = spi_stop;
                    end
          default: next_mode = spi_run;
     endcase
   end

 // ---------------- Status register (SPIF, SPTEF, MODF) ----------------
 // Pure combinational decode (no latch). During reset SPI_DR = 0 and SS = 1,
 // so SPI_SR evaluates to its reset value 8'b0010_0000 (SPTEF = 1).
 assign sptef  = (SPI_DR == 8'b0000_0000);   // transmit data register empty
 assign spif   = (SPI_DR != 8'b0000_0000);   // data available
 assign SPI_SR = {spif, 1'b0, sptef, modf, 4'b0000};

endmodule
