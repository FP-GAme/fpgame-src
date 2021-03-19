module io_subsystem (

);

snes_controller ctrl (
    .con_serial(),
    .clock(),
    .reset(),
    .con_clock(),
    .con_latch()
);

endmodule : io_subsystem
