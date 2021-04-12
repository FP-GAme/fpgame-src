/* dma_engine.v
 * Performs a 128-bit data width DMA of an entire VRAM, using the CPU's local copy as a source
 *   (controlled by src_addr) and the CPU-Facing VRAM as a target.
 *
 * This HDL is modified from the Altera-provided Platform Designer IP altera_avalon_dma.
 * Most notably, it doesn't use registers or an awkward Avalon interface to acccept configuration
 *   data from the vram_dma_controller. It is simply tied to the vram_dma_controller via conduit
 *   (wires).
 * It is also hardwired to perform only Quadword (128-bit) reads from the source.
 * The interrupt mechanism has been replaced with a simple "done" signal which is wired via conduit.
 */

//Legal Notice: (C)2021 Altera Corporation. All rights reserved.  Your
//use of Altera Corporation's design tools, logic functions and other
//software and tools, and its AMPP partner logic functions, and any
//output files any of the foregoing (including device programming or
//simulation files), and any associated documentation or information are
//expressly subject to the terms and conditions of the Altera Program
//License Subscription Agreement or other applicable license agreement,
//including, without limitation, that your use is for the sole purpose
//of programming logic devices manufactured by Altera and sold by Altera
//or its authorized distributors.  Please refer to the applicable
//agreement for further details.

// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on

// turn off superfluous verilog processor warnings 
// altera message_level Level1 
// altera message_off 10034 10035 10036 10037 10230 10240 10030 

module dma_engine_byteenables (
                                      // inputs:
                                       quadword,
                                       write_address,

                                      // outputs:
                                       write_byteenable
                                    )
;

  output  [ 15: 0] write_byteenable;
  input            quadword;
  input   [ 15: 0] write_address;


wire             wa_3_to_0_is_0;
wire             wa_3_to_0_is_1;
wire             wa_3_to_0_is_10;
wire             wa_3_to_0_is_11;
wire             wa_3_to_0_is_12;
wire             wa_3_to_0_is_13;
wire             wa_3_to_0_is_14;
wire             wa_3_to_0_is_15;
wire             wa_3_to_0_is_2;
wire             wa_3_to_0_is_3;
wire             wa_3_to_0_is_4;
wire             wa_3_to_0_is_5;
wire             wa_3_to_0_is_6;
wire             wa_3_to_0_is_7;
wire             wa_3_to_0_is_8;
wire             wa_3_to_0_is_9;
wire    [ 15: 0] write_byteenable;
  assign wa_3_to_0_is_15 = write_address[3 : 0] == 4'hF;
  assign wa_3_to_0_is_14 = write_address[3 : 0] == 4'hE;
  assign wa_3_to_0_is_13 = write_address[3 : 0] == 4'hD;
  assign wa_3_to_0_is_12 = write_address[3 : 0] == 4'hC;
  assign wa_3_to_0_is_11 = write_address[3 : 0] == 4'hB;
  assign wa_3_to_0_is_10 = write_address[3 : 0] == 4'hA;
  assign wa_3_to_0_is_9 = write_address[3 : 0] == 4'h9;
  assign wa_3_to_0_is_8 = write_address[3 : 0] == 4'h8;
  assign wa_3_to_0_is_7 = write_address[3 : 0] == 4'h7;
  assign wa_3_to_0_is_6 = write_address[3 : 0] == 4'h6;
  assign wa_3_to_0_is_5 = write_address[3 : 0] == 4'h5;
  assign wa_3_to_0_is_4 = write_address[3 : 0] == 4'h4;
  assign wa_3_to_0_is_3 = write_address[3 : 0] == 4'h3;
  assign wa_3_to_0_is_2 = write_address[3 : 0] == 4'h2;
  assign wa_3_to_0_is_1 = write_address[3 : 0] == 4'h1;
  assign wa_3_to_0_is_0 = write_address[3 : 0] == 4'h0;
  assign write_byteenable = ({16 {quadword}} & 16'b1111111111111111);

endmodule


// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on

// turn off superfluous verilog processor warnings 
// altera message_level Level1 
// altera message_off 10034 10035 10036 10037 10230 10240 10030 

module dma_engine_fifo_module_fifo_ram_module (
                                                      // inputs:
                                                       clk,
                                                       data,
                                                       rdaddress,
                                                       rdclken,
                                                       reset_n,
                                                       wraddress,
                                                       wrclock,
                                                       wren,

                                                      // outputs:
                                                       q
                                                    )
;

  output  [127: 0] q;
  input            clk;
  input   [127: 0] data;
  input   [  4: 0] rdaddress;
  input            rdclken;
  input            reset_n;
  input   [  4: 0] wraddress;
  input            wrclock;
  input            wren;


reg     [127: 0] mem_array [ 31: 0];
wire    [127: 0] q;
reg     [  4: 0] read_address;

//synthesis translate_off
//////////////// SIMULATION-ONLY CONTENTS
  always @(posedge clk or negedge reset_n)
    begin
      if (reset_n == 0)
          read_address <= 0;
      else if (rdclken)
          read_address <= rdaddress;
    end


  // Data read is synchronized through latent_rdaddress.
  assign q = mem_array[read_address];

  always @(posedge wrclock)
    begin
      // Write data
      if (wren)
          mem_array[wraddress] <= data;
    end



//////////////// END SIMULATION-ONLY CONTENTS

//synthesis translate_on
//synthesis read_comments_as_HDL on
//  always @(rdaddress)
//    begin
//      read_address = rdaddress;
//    end
//
//
//  lpm_ram_dp lpm_ram_dp_component
//    (
//      .data (data),
//      .q (q),
//      .rdaddress (read_address),
//      .rdclken (rdclken),
//      .rdclock (clk),
//      .wraddress (wraddress),
//      .wrclock (wrclock),
//      .wren (wren)
//    );
//
//  defparam lpm_ram_dp_component.lpm_file = "UNUSED",
//           lpm_ram_dp_component.lpm_hint = "USE_EAB=ON",
//           lpm_ram_dp_component.lpm_indata = "REGISTERED",
//           lpm_ram_dp_component.lpm_outdata = "UNREGISTERED",
//           lpm_ram_dp_component.lpm_rdaddress_control = "REGISTERED",
//           lpm_ram_dp_component.lpm_width = 128,
//           lpm_ram_dp_component.lpm_widthad = 5,
//           lpm_ram_dp_component.lpm_wraddress_control = "REGISTERED",
//           lpm_ram_dp_component.suppress_memory_conversion_warnings = "ON";
//
//synthesis read_comments_as_HDL off

endmodule


// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on

// turn off superfluous verilog processor warnings 
// altera message_level Level1 
// altera message_off 10034 10035 10036 10037 10230 10240 10030 

module dma_engine_fifo_module (
                                      // inputs:
                                       clk,
                                       clk_en,
                                       fifo_read,
                                       fifo_wr_data,
                                       fifo_write,
                                       flush_fifo,
                                       inc_pending_data,
                                       reset_n,

                                      // outputs:
                                       fifo_datavalid,
                                       fifo_empty,
                                       fifo_rd_data,
                                       p1_fifo_full
                                    )
;

  output           fifo_datavalid;
  output           fifo_empty;
  output  [127: 0] fifo_rd_data;
  output           p1_fifo_full;
  input            clk;
  input            clk_en;
  input            fifo_read;
  input   [127: 0] fifo_wr_data;
  input            fifo_write;
  input            flush_fifo;
  input            inc_pending_data;
  input            reset_n;


wire    [  4: 0] estimated_rdaddress;
reg     [  4: 0] estimated_wraddress;
wire             fifo_datavalid;
wire             fifo_dec;
reg              fifo_empty;
reg              fifo_full;
wire             fifo_inc;
wire    [127: 0] fifo_ram_q;
wire    [127: 0] fifo_rd_data;
reg              last_write_collision;
reg     [127: 0] last_write_data;
wire    [  4: 0] p1_estimated_wraddress;
wire             p1_fifo_empty;
wire             p1_fifo_full;
wire    [  4: 0] p1_wraddress;
wire    [  4: 0] rdaddress;
reg     [  4: 0] rdaddress_reg;
reg     [  4: 0] wraddress;
wire             write_collision;
  assign p1_wraddress = (fifo_write)? wraddress - 1 :
    wraddress;

  always @(posedge clk or negedge reset_n)
    begin
      if (reset_n == 0)
          wraddress <= 0;
      else if (clk_en)
          if (flush_fifo)
              wraddress <= 0;
          else 
            wraddress <= p1_wraddress;
    end


  assign rdaddress = flush_fifo ? 0 : fifo_read ? (rdaddress_reg - 1) : rdaddress_reg;
  always @(posedge clk or negedge reset_n)
    begin
      if (reset_n == 0)
          rdaddress_reg <= 0;
      else 
        rdaddress_reg <= rdaddress;
    end


  assign fifo_datavalid = ~fifo_empty;
  assign fifo_inc = fifo_write & ~fifo_read;
  assign fifo_dec = fifo_read & ~fifo_write;
  assign estimated_rdaddress = rdaddress_reg - 1;
  assign p1_estimated_wraddress = (inc_pending_data)? estimated_wraddress - 1 :
    estimated_wraddress;

  always @(posedge clk or negedge reset_n)
    begin
      if (reset_n == 0)
          estimated_wraddress <= {5 {1'b1}};
      else if (clk_en)
          if (flush_fifo)
              estimated_wraddress <= {5 {1'b1}};
          else 
            estimated_wraddress <= p1_estimated_wraddress;
    end


  assign p1_fifo_empty = flush_fifo  | ((~fifo_inc & fifo_empty) | (fifo_dec & (wraddress == estimated_rdaddress)));
  always @(posedge clk or negedge reset_n)
    begin
      if (reset_n == 0)
          fifo_empty <= 1;
      else if (clk_en)
          fifo_empty <= p1_fifo_empty;
    end


  assign p1_fifo_full = ~flush_fifo & ((~fifo_dec & fifo_full)  | (inc_pending_data & (estimated_wraddress == rdaddress)));
  always @(posedge clk or negedge reset_n)
    begin
      if (reset_n == 0)
          fifo_full <= 0;
      else if (clk_en)
          fifo_full <= p1_fifo_full;
    end


  assign write_collision = fifo_write && (wraddress == rdaddress);
  always @(posedge clk or negedge reset_n)
    begin
      if (reset_n == 0)
          last_write_data <= 0;
      else if (write_collision)
          last_write_data <= fifo_wr_data;
    end


  always @(posedge clk or negedge reset_n)
    begin
      if (reset_n == 0)
          last_write_collision <= 0;
      else if (write_collision)
          last_write_collision <= -1;
      else if (fifo_read)
          last_write_collision <= 0;
    end


  assign fifo_rd_data = last_write_collision ? last_write_data : fifo_ram_q;
  //dma_engine_fifo_module_fifo_ram, which is an e_ram
  dma_engine_fifo_module_fifo_ram_module dma_engine_fifo_module_fifo_ram
    (
      .clk       (clk),
      .data      (fifo_wr_data),
      .q         (fifo_ram_q),
      .rdaddress (rdaddress),
      .rdclken   (1'b1),
      .reset_n   (reset_n),
      .wraddress (wraddress),
      .wrclock   (clk),
      .wren      (fifo_write)
    );


endmodule


// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on

// turn off superfluous verilog processor warnings 
// altera message_level Level1 
// altera message_off 10034 10035 10036 10037 10230 10240 10030 

module dma_engine_mem_read (
                                   // inputs:
                                    clk,
                                    clk_en,
                                    go,
                                    p1_done_read,
                                    p1_fifo_full,
                                    read_waitrequest,
                                    reset_n,

                                   // outputs:
                                    inc_read,
                                    mem_read_n
                                 )
;

  output           inc_read;
  output           mem_read_n;
  input            clk;
  input            clk_en;
  input            go;
  input            p1_done_read;
  input            p1_fifo_full;
  input            read_waitrequest;
  input            reset_n;


reg              dma_engine_mem_read_access;
reg              dma_engine_mem_read_idle;
wire             inc_read;
wire             mem_read_n;
wire             p1_read_select;
reg              read_select;
  assign mem_read_n = ~read_select;
  always @(posedge clk or negedge reset_n)
    begin
      if (reset_n == 0)
          read_select <= 0;
      else if (clk_en)
          read_select <= p1_read_select;
    end


  assign inc_read = read_select & ~read_waitrequest;
  // Transitions into state 'idle'.
  always @(posedge clk or negedge reset_n)
    begin
      if (reset_n == 0)
          dma_engine_mem_read_idle <= 1;
      else if (clk_en)
          dma_engine_mem_read_idle <= ((dma_engine_mem_read_idle == 1) & (go == 0)) |
                    ((dma_engine_mem_read_idle == 1) & (p1_done_read == 1)) |
                    ((dma_engine_mem_read_idle == 1) & (p1_fifo_full == 1)) |
                    ((dma_engine_mem_read_access == 1) & (read_waitrequest == 0) & (p1_fifo_full == 1)) |
                    ((dma_engine_mem_read_access == 1) & (p1_done_read == 1) & (read_waitrequest == 0));

    end


  // Transitions into state 'access'.
  always @(posedge clk or negedge reset_n)
    begin
      if (reset_n == 0)
          dma_engine_mem_read_access <= 0;
      else if (clk_en)
          dma_engine_mem_read_access <= ((dma_engine_mem_read_idle == 1) & (go == 1) & (p1_done_read == 0) & (p1_fifo_full == 0)) |
                    ((dma_engine_mem_read_access == 1) & (read_waitrequest == 1)) |
                    ((dma_engine_mem_read_access == 1) & (p1_done_read == 0) & (p1_fifo_full == 0) & (read_waitrequest == 0));

    end


  assign p1_read_select = ({1 {((dma_engine_mem_read_access && (read_waitrequest == 1)))}} & 1) |
    ({1 {((dma_engine_mem_read_access && (p1_done_read == 0) && (p1_fifo_full == 0) && (read_waitrequest == 0)))}} & 1) |
    ({1 {((dma_engine_mem_read_idle && (go == 1) && (p1_done_read == 0) && (p1_fifo_full == 0)))}} & 1);


endmodule


// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on

// turn off superfluous verilog processor warnings 
// altera message_level Level1 
// altera message_off 10034 10035 10036 10037 10230 10240 10030 

module dma_engine_mem_write (
    input  wire d1_enabled_write_endofpacket,
    input  wire fifo_datavalid,
    input  wire write_waitrequest,
    output wire fifo_read,
    output wire inc_write,
    output wire mem_write_n,
    output wire write_select
);
    assign write_select = fifo_datavalid & ~d1_enabled_write_endofpacket;
    assign mem_write_n = ~write_select;
    assign fifo_read = write_select & ~write_waitrequest;
    assign inc_write = fifo_read;
endmodule


// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on

// turn off superfluous verilog processor warnings 
// altera message_level Level1 
// altera message_off 10034 10035 10036 10037 10230 10240 10030 

//DMA peripheral dma_engine
//Read slaves:
//hps_0_bridges.f2h_sdram1_data; 
//Write slaves:
//h2f_vram_interface_0.avs_s0; 

module dma_engine (
    input  wire         clk,
    input  wire         system_reset_n,

    // control conduit:
    input  wire [31:0]  dma_engine_src_addr,
    input  wire         dma_engine_start,
    output wire         dma_engine_finish,

    // read_master:
    output wire [31:0]  read_address,
    output wire         read_chipselect,
    output wire         read_read_n,
    input  wire [127:0] read_readdata,
    input  wire         read_readdatavalid,
    input  wire         read_waitrequest,

    // write_master:
    output wire [15:0]  write_address,
    output wire [15:0]  write_byteenable,
    output wire         write_chipselect,
    output wire         write_write_n,
    output wire [127:0] write_writedata,
    input  wire         write_waitrequest

) /* synthesis ALTERA_ATTRIBUTE = "SUPPRESS_DA_RULE_INTERNAL=\"R101\"" */ ;

    wire             clk_en;
    reg              d1_done_transaction;
    reg              done;
    wire             done_transaction;
    reg              done_write;
    wire             fifo_datavalid;
    wire             fifo_empty;
    wire    [127: 0] fifo_rd_data;
    wire    [127: 0] fifo_rd_data_as_quadword;
    wire             fifo_read;
    wire    [127: 0] fifo_wr_data;
    wire             fifo_write;
    wire             fifo_write_data_valid;
    wire             flush_fifo;
    wire             inc_read;
    wire             inc_write;
    wire             leen;
    reg     [ 31: 0] length;
    reg              length_eq_0;
    wire             mem_read_n;
    wire             mem_write_n;
    wire             p1_done_read;
    wire             p1_done_write;
    wire             p1_fifo_full;
    wire    [ 31: 0] p1_length;
    wire             p1_length_eq_0;
    wire    [ 31: 0] p1_readaddress;
    wire    [ 15: 0] p1_writeaddress;
    wire    [ 31: 0] p1_writelength;
    wire             p1_writelength_eq_0;
    wire             quadword;
    reg     [ 31: 0] readaddress;
    wire    [  4: 0] readaddress_inc;

    // Internal reset
    wire             reset_n; // originally reg

    // Warning, confusingly named
    reg     [ 15: 0] writeaddress;
    wire    [  4: 0] writeaddress_inc;
    // Write internal wires
    wire             write_select;
    reg     [ 31: 0] writelength;
    reg              writelength_eq_0;

    // custom
    reg started;

    assign clk_en = 1;
    assign fifo_wr_data = read_readdata;

  //write_master, which is an e_avalon_master
  dma_engine_byteenables the_dma_engine_byteenables
    (
      .quadword         (quadword),
      .write_address    (write_address),
      .write_byteenable (write_byteenable)
    );


    assign read_read_n = mem_read_n;

    // ============================
    // === Read Address Control ===
    // ============================
    always @(posedge clk or negedge reset_n) begin
        if (reset_n == 0)
            readaddress <= 32'h0;
        else if (clk_en)
            readaddress <= p1_readaddress;
    end

    assign p1_readaddress = (dma_engine_start && !started) ? dma_engine_src_addr :
                            (inc_read) ? (readaddress + readaddress_inc) : readaddress;

    // =============================
    // === Write Address Control ===
    // =============================
    localparam START_WRADDRESS = 16'h0; // Always starts at 0.
    always @(posedge clk or negedge reset_n) begin
        if (reset_n == 0)
            writeaddress <= 16'h0;
        else if (clk_en)
            writeaddress <= p1_writeaddress;
    end

    // TODO: May need to reset module after every run. Otherwise, writeaddress won't return to starting value
    assign p1_writeaddress = (dma_engine_start && !started) ? START_WRADDRESS :
                             (inc_write) ? (writeaddress + writeaddress_inc) : writeaddress;

    // ======================
    // === Length Control ===
    // ======================
    // vram length in bytes
    localparam START_VRAM_LENGTH = 32'hD140;

    // length in bytes
    always @(posedge clk or negedge reset_n) begin
        if (reset_n == 0)
            length <= 32'h0;
        else if (clk_en)
            length <= p1_length;
    end

    assign p1_length = (dma_engine_start && !started) ? START_VRAM_LENGTH :
                       ((inc_read && (!length_eq_0))) ? length - {quadword, 4'b0} : length;

    // ============================================================
    // === Write Master Length Control (Copy of Length Control) ===
    // ============================================================
    // write master length
    always @(posedge clk or negedge reset_n) begin
        if (reset_n == 0)
            writelength <= 32'h0;
        else if (clk_en)
            writelength <= p1_writelength;
        end

    assign p1_writelength = (dma_engine_start && !started) ? START_VRAM_LENGTH :
                            ((inc_write && (!writelength_eq_0))) ? writelength - {quadword, 4'b0} : writelength;

    // ===================================
    // === Write Length Equals 0 Logic ===
    // ===================================
    assign p1_writelength_eq_0 = inc_write && (!writelength_eq_0) && ((writelength  - {quadword, 1'b0, 1'b0, 1'b0, 1'b0}) == 0);
    assign p1_length_eq_0 = inc_read && (!length_eq_0) && ((length  - {quadword, 1'b0, 1'b0, 1'b0, 1'b0}) == 0);

    always @(posedge clk or negedge reset_n) begin
        if (reset_n == 0)
            length_eq_0 <= 1;
        else if (clk_en)
            if (dma_engine_start && !started)
                length_eq_0 <= 0;
            else if (p1_length_eq_0)
                length_eq_0 <= -1;
    end

    always @(posedge clk or negedge reset_n) begin
        if (reset_n == 0)
            writelength_eq_0 <= 1;
        else if (clk_en)
            if (dma_engine_start && !started)
                writelength_eq_0 <= 0;
            else if (p1_writelength_eq_0)
                writelength_eq_0 <= -1;
    end

    // ====================================
    // === Read/Write Address Increment ===
    // ====================================
    // They should always increment with the given settings.
    assign writeaddress_inc = {quadword, 1'b0, 1'b0, 1'b0, 1'b0};
    assign readaddress_inc = {quadword, 1'b0, 1'b0, 1'b0, 1'b0};

    // ===========================
    // === Start and End Logic ===
    // ===========================
    // Only assert done signal for one cycle after being done.
    // Reset state upon starting.
    always @(posedge clk or negedge reset_n) begin
        if (reset_n == 1'b0) begin
            done <= 1'b0;
            started <= 1'b0;
        end
        else if (clk_en) begin
            if (!started && dma_engine_start) begin
                started <= 1'b1;
                done <= 1'b0;
            end
            if (started && done_write) begin
                done <= 1'b1;
                // reset started signal when done. This also ensures done signal is sent only once.
                started <= 1'b0;
            end
            else begin
              done <= 0;
            end
        end
    end


    // ======================================
    // === Hardwired Settings Assignments ===
    // ======================================
    assign leen = 1'b1; // TODO: Just replace with 1 everywhere
    assign quadword = 1'b1;
    assign dma_engine_finish = done;

    // =================
    // === ??? Logic ===
    // =================

    assign flush_fifo = done;
    dma_engine_fifo_module the_dma_engine_fifo_module (
        .clk              (clk),
        .clk_en           (clk_en),
        .fifo_datavalid   (fifo_datavalid),
        .fifo_empty       (fifo_empty),
        .fifo_rd_data     (fifo_rd_data),
        .fifo_read        (fifo_read),
        .fifo_wr_data     (fifo_wr_data),
        .fifo_write       (fifo_write),
        .flush_fifo       (flush_fifo),
        .inc_pending_data (inc_read),
        .p1_fifo_full     (p1_fifo_full),
        .reset_n          (reset_n)
    );

    //the_dma_engine_mem_read, which is an e_instance
    dma_engine_mem_read the_dma_engine_mem_read (
        .clk              (clk),
        .clk_en           (clk_en),
        .go               (started),
        .inc_read         (inc_read),
        .mem_read_n       (mem_read_n),
        .p1_done_read     (p1_done_read),
        .p1_fifo_full     (p1_fifo_full),
        .read_waitrequest (read_waitrequest),
        .reset_n          (reset_n)
    );

    assign fifo_write = fifo_write_data_valid;

    dma_engine_mem_write the_dma_engine_mem_write (
        .d1_enabled_write_endofpacket (1'b0), // we disabled end-of-packet functionality
        .fifo_datavalid               (fifo_datavalid),
        .fifo_read                    (fifo_read),
        .inc_write                    (inc_write),
        .mem_write_n                  (mem_write_n),
        .write_select                 (write_select),
        .write_waitrequest            (write_waitrequest)
    );

    assign p1_done_read = (leen && (p1_length_eq_0 || (length_eq_0))) | p1_done_write;
    assign p1_done_write = (leen && (p1_writelength_eq_0 || writelength_eq_0));

    // Write has completed when the length goes to 0, or
    always @(posedge clk or negedge reset_n) begin
        if (reset_n == 0)
            done_write <= 0;
        else if (clk_en)
            done_write <= p1_done_write;
    end

    assign read_address = readaddress;
    assign write_address = writeaddress;
    assign write_chipselect = write_select;
    assign read_chipselect = ~read_read_n;
    assign write_write_n = mem_write_n;

    assign fifo_rd_data_as_quadword = fifo_rd_data[127 : 0];
    assign write_writedata = ({128 {quadword}} & fifo_rd_data_as_quadword);

    assign fifo_write_data_valid = read_readdatavalid;

    assign reset_n = system_reset_n;

endmodule