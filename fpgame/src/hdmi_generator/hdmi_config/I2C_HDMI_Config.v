module I2C_HDMI_Config (
    // Host Side
    input wire iCLK,
    input wire iRST_N,
    //  I2C Side
    output wire I2C_SCLK,
    inout wire I2C_SDAT,
    input wire HDMI_TX_INT
);

//  Internal Registers/Wires
reg [15:0] mI2C_CLK_DIV;
reg [23:0] mI2C_DATA;
reg mI2C_CTRL_CLK;
reg mI2C_GO;
wire mI2C_END;
wire mI2C_ACK;
reg [15:0] LUT_DATA;
reg [4:0] LUT_INDEX;
reg [3:0] mSetup_ST;

// Clock Setting
parameter CLK_Freq = 50000000; // 50 MHz
parameter I2C_Freq = 20000; // 20 KHz

// # of LUT Commands to send
parameter LUT_SIZE = 23;

/////////////////////   I2C Control Clock   ////////////////////////
always @(posedge iCLK or negedge iRST_N)
begin
    if(!iRST_N)
    begin
        mI2C_CTRL_CLK <= 0;
        mI2C_CLK_DIV  <= 0;
    end
    else
    begin
        if( mI2C_CLK_DIV < (CLK_Freq/I2C_Freq) )
            mI2C_CLK_DIV <= mI2C_CLK_DIV+1;
        else
        begin
            mI2C_CLK_DIV  <= 0;
            mI2C_CTRL_CLK <= ~mI2C_CTRL_CLK;
        end
    end
end
////////////////////////////////////////////////////////////////////
I2C_Controller u0 (
    .CLOCK(mI2C_CTRL_CLK), //  Controller Work Clock
    .I2C_SCLK(I2C_SCLK),   //  I2C CLOCK
    .I2C_SDAT(I2C_SDAT),   //  I2C DATA
    .I2C_DATA(mI2C_DATA),  //  DATA:[SLAVE_ADDR,SUB_ADDR,DATA]
    .GO(mI2C_GO),          //  GO transfor
    .END(mI2C_END),        //  END transfor 
    .ACK(mI2C_ACK),        //  ACK
    .RESET(iRST_N)
);
////////////////////////////////////////////////////////////////////
//////////////////////  Config Control  ////////////////////////////
always @(posedge mI2C_CTRL_CLK or negedge iRST_N)
begin
    if(!iRST_N) begin
        LUT_INDEX <= 0;
        mSetup_ST <= 0;
        mI2C_GO   <= 0;
    end
    else begin
        if(LUT_INDEX<LUT_SIZE)
        begin
            case(mSetup_ST)
            0: begin
                mI2C_DATA <= {8'h72,LUT_DATA};
                mI2C_GO   <= 1;
                mSetup_ST <= 1;
            end
            1: begin
                if(mI2C_END) begin
                    if(!mI2C_ACK)
                        mSetup_ST <= 2;
                    else
                        mSetup_ST <= 0;                          
                        mI2C_GO   <= 0;
                end
            end
            2: begin
                LUT_INDEX <= LUT_INDEX+1;
                mSetup_ST <= 0;
            end
            endcase
        end
        else begin
            if(!HDMI_TX_INT) begin
                LUT_INDEX <= 0;
            end
            else
                LUT_INDEX <= LUT_INDEX;
        end
    end
end
////////////////////////////////////////////////////////////////////
/////////////////////   Config Data LUT   //////////////////////////    
always begin
    case(LUT_INDEX)
    // === Mandatory Power-up Sequence ===
    0: LUT_DATA <= 16'h4110; // Power on
    1: LUT_DATA <= 16'h9803; // Must be set to a fixed value
    2: LUT_DATA <= 16'h9AE0; // Must be set to a fixed value
    3: LUT_DATA <= 16'h9C30; // Must be set to a fixed value
    4: LUT_DATA <= 16'h9D61; // Must be set to a fixed value
    5: LUT_DATA <= 16'hA2A4; // Must be set to a fixed value
    6: LUT_DATA <= 16'hA3A4; // Must be set to a fixed value
    7: LUT_DATA <= 16'hE0D0; // Must be set to a fixed value
    8: LUT_DATA <= 16'hF900; // Must be set to a fixed value
    
    // === Video & Audio Config ===
    9: LUT_DATA <= 16'h1530; // 24-bit RGB, H/V-Sync, 32KHz Audio
    
    // === Video Config ===
    10:LUT_DATA <= 16'h1630; // Sets 4:4:4 RGB input style
    11:LUT_DATA <= 16'hAF16; // Enables HDMI mode
    12:LUT_DATA <= 16'h5510; // Setup InfoFrame for RGB
    13:LUT_DATA <= 16'h5618; // Tell InfoFrame about our 4:3 Aspect Ratio
    14:LUT_DATA <= 16'hBA60; // Set video input clock delay to 0
    
    // === Audio Config ===
    15: LUT_DATA <= 16'h0100; // Set N[19:16]
    16: LUT_DATA <= 16'h0211; // Set N[15:8]
    17: LUT_DATA <= 16'h03E0; // Set N[7:0]
    18: LUT_DATA <= 16'h0702; // Set CTS[19:16]
    19: LUT_DATA <= 16'h0881; // Set CTS[15:8]
    20: LUT_DATA <= 16'h0925; // Set CTS[7:0]
    21: LUT_DATA <= 16'h0C84; // Disable all I2S channels other than I2S0 (the one we use)
    22: LUT_DATA <= 16'h7301; // Tell InfoFrame we have 2 channels (I2S0) 

    default: LUT_DATA <= 16'h9803; // Just write to this fixed register
    endcase
end
////////////////////////////////////////////////////////////////////
endmodule
