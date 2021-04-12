/* pio_write_w_avail.sv
 * An MMIO Accessible Register which the CPU writes to over an Avalon Bus.
 * In particular, the write_valid signal is exposed and held high until the FPGA logic manually
 *   resets it. This new signal is called the write_avail signal.
 * The write_avail signal essentially tells the FPGA whether there has been an update/write from the
 *   cpu since the FPGA's last read.
 */

module pio_write_w_avail # (
    parameter DATA_WIDTH = 32
)(
    input  logic                  clk,
    input  logic                  rst_n,

    // Avalon Slave
    input  logic [1:0]            avs_s0_address, // Actually used to select this interface
    input  logic                  avs_s0_chipselect, // Actually used to select this interface
    input  logic                  avs_s0_write_n,
    input  logic [DATA_WIDTH-1:0] avs_s0_writedata,

    // Conduit
    output logic                  update_avail,
    output logic [DATA_WIDTH-1:0] rddata,
    input  logic                  read_rst    // "Ack" signal tells this PIO to reset write_avail
);

    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            update_avail <= 1'b0;
            rddata <= '0;
        end
        else if (!avs_s0_write_n && avs_s0_chipselect && avs_s0_address == 2'd0) begin
            // The last "if condition" is copied from a generated pio example to ensure behaviour is
            //   identical. Technically the address is not needed, but Qsys uses it to determine how
            //   wide of an MMIO region is necessary to map.
            rddata <= avs_s0_writedata;
            update_avail <= 1'b1;
        end
        else if (read_rst) begin
            // Notice that CPU->PIO write takes priority over the read reset.
            // In the rare case that a read_rst and avs_s0_write occur at once, the old data will be
            //   read by the FPGA reader, the data will be updated by the CPU, and write_avail will
            //   remain high, indicating new data is available.
            update_avail <= 1'b0;
        end
        else begin
            update_avail <= update_avail;
            rddata       <= rddata;
        end
    end

endmodule : pio_write_w_avail
