/* Copyright Text
// ============================================================================
// Copyright (c) 2012 by Terasic Technologies Inc.
// ============================================================================
//
// Permission:
//
//   Terasic grants permission to use and modify this code for use
//   in synthesis for all Terasic Development Boards and Altera Development 
//   Kits made by Terasic.  Other use of this code, including the selling 
//   ,duplication, or modification of any portion is strictly prohibited.
//
// Disclaimer:
//
//   This VHDL/Verilog or C/C++ source code is intended as a design reference
//   which illustrates how these types of functions can be implemented.
//   It is the user's responsibility to verify their design for
//   consistency and functionality through the use of formal
//   verification methods.  Terasic provides no warranty regarding the use 
//   or functionality of this code.
//
// ============================================================================
//           
//  Terasic Technologies Inc
//  9F., No.176, Sec.2, Gongdao 5th Rd, East Dist, Hsinchu City, 30070. Taiwan
//
//
//
//                     web: http://www.terasic.com/
//                     email: support@terasic.com
//
// ============================================================================
*/

/* === Outdated Description Text ===
Function: 
	ADV7513 Video and Audio Control 
	
I2C Configuration Requirements:
	Master Mode
	I2S, 16-bits
	
Clock:
	input Clock 1.536MHz (48K*Data_Width*Channel_Num)
	
Revision:
	1.0, 10/06/2014, Init by Nick
	
Compatibility:
	Quartus 14.0.2
*/

/* === Modification Notes ===
Fractional PLL generates 1.024MHz (32KHz * 16 data width * 2 channels) instead of 1.536MHz
*/

module AUDIO_IF (
    input wire audio_clk, // 1.024MHz clock
    input wire rst_n,
    output wire sclk,
    output reg lrclk,
    output reg [3:0] i2s
);

parameter DATA_WIDTH = 16;
parameter SIN_SAMPLE_DATA = 32;

// === Internal wires and registers Declarations ===
reg [5:0] sclk_Count;
reg [5:0] Simple_count;
reg [15:0] Data_Bit;
reg [6:0] Data_Count;
reg [5:0] SIN_Cont;

assign sclk = audio_clk;

// === Sequential logic ===
always@(negedge  sclk or negedge rst_n)
begin
	if(!rst_n)
	begin
	  lrclk<=0;
	  sclk_Count<=0;
	end
	
	else if(sclk_Count>=DATA_WIDTH-1)
	begin
	  sclk_Count <= 0;
	  lrclk <= ~lrclk;
	end
	else 
     sclk_Count <= sclk_Count + 6'b1;
end
 
always@(negedge sclk or negedge rst_n)
begin
  if(!rst_n)
  begin
    Data_Count <= 0;
  end
  else
  begin
    if(Data_Count >= DATA_WIDTH-1)
	 begin
      Data_Count <= 0;
    end
	 else 
	 Data_Count <= Data_Count + 7'b1;
  end
end

always@(negedge sclk or negedge rst_n)
begin
  if(!rst_n)
  begin
    i2s <= 0;
  end
  else
  begin
    i2s[0] <= Data_Bit[~Data_Count];
	 i2s[1] <= Data_Bit[~Data_Count];
	 i2s[2] <= Data_Bit[~Data_Count];
	 i2s[3] <= Data_Bit[~Data_Count];
  end
end

always@(negedge lrclk or negedge rst_n)
begin
	if(!rst_n)
	  SIN_Cont	<=	0;
	else
	begin
		if(SIN_Cont < SIN_SAMPLE_DATA-1 )
		SIN_Cont	<=	SIN_Cont+6'b1;
		else
		SIN_Cont	<=	0;
	end
end

// === Combinational logic ===
always@(SIN_Cont)
begin
	case(SIN_Cont)
		 0  :   Data_Bit      <=      0       ;
		 1  :   Data_Bit      <=      630     ;
		 2  :   Data_Bit      <=      2494    ;
		 3  :   Data_Bit      <=      5522    ;
		 4  :   Data_Bit      <=      9597    ;
		 5  :   Data_Bit      <=      14563   ;
		 6  :   Data_Bit      <=      20228   ;
		 7  :   Data_Bit      <=      26375   ;
		 8  :   Data_Bit      <=      32768   ;
		 9  :   Data_Bit      <=      39160   ;
		 10  :  Data_Bit      <=      45307   ;
		 11  :  Data_Bit      <=      50972   ;
		 12  :  Data_Bit      <=      55938   ;
		 13  :  Data_Bit      <=      60013   ;
		 14  :  Data_Bit      <=      63041   ;
		 15  :  Data_Bit      <=      64905   ;
		 16  :  Data_Bit      <=      65535   ;
		 17  :  Data_Bit      <=      64905   ;
		 18  :  Data_Bit      <=      63041   ;
		 19  :  Data_Bit      <=      60013   ;
		 20  :  Data_Bit      <=      55938   ;
		 21  :  Data_Bit      <=      50972   ;
		 22  :  Data_Bit      <=      45307   ;
		 23  :  Data_Bit      <=      39160   ;
		 24  :  Data_Bit      <=      32768   ;
		 25  :  Data_Bit      <=      26375   ;
		 26  :  Data_Bit      <=      20228   ;
		 27  :  Data_Bit      <=      14563   ;
		 28  :  Data_Bit      <=      9597    ;
		 29  :  Data_Bit      <=      5522    ;
		 30  :  Data_Bit      <=      2494    ;
	    31  :  Data_Bit      <=      630     ;
	default	:
		   Data_Bit		<=		0		;
	endcase
	
end
endmodule
