# TCL File Generated by Component Editor 20.1
# Fri Apr 09 21:44:08 EDT 2021
# DO NOT MODIFY


# 
# ppu_dma_interface "PPU DMA Interface" v1.0
#  2021.04.09.21:44:08
# 
# 

# 
# request TCL package from ACDS 16.1
# 
package require -exact qsys 16.1


# 
# module ppu_dma_interface
# 
set_module_property DESCRIPTION ""
set_module_property NAME ppu_dma_interface
set_module_property VERSION 1.0
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property AUTHOR ""
set_module_property DISPLAY_NAME "PPU DMA Interface"
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property REPORT_TO_TALKBACK false
set_module_property ALLOW_GREYBOX_GENERATION false
set_module_property REPORT_HIERARCHY false


# 
# file sets
# 
add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL ppu_dma_interface
set_fileset_property QUARTUS_SYNTH ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property QUARTUS_SYNTH ENABLE_FILE_OVERWRITE_MODE true
add_fileset_file ppu_dma_interface.sv SYSTEM_VERILOG PATH src/ppu/ppu_dma_interface/ppu_dma_interface.sv TOP_LEVEL_FILE


# 
# parameters
# 


# 
# display items
# 


# 
# connection point clock
# 
add_interface clock clock end
set_interface_property clock clockRate 0
set_interface_property clock ENABLED true
set_interface_property clock EXPORT_OF ""
set_interface_property clock PORT_NAME_MAP ""
set_interface_property clock CMSIS_SVD_VARIABLES ""
set_interface_property clock SVD_ADDRESS_GROUP ""

add_interface_port clock clock_clk clk Input 1


# 
# connection point reset
# 
add_interface reset reset end
set_interface_property reset associatedClock clock
set_interface_property reset synchronousEdges DEASSERT
set_interface_property reset ENABLED true
set_interface_property reset EXPORT_OF ""
set_interface_property reset PORT_NAME_MAP ""
set_interface_property reset CMSIS_SVD_VARIABLES ""
set_interface_property reset SVD_ADDRESS_GROUP ""

add_interface_port reset reset_reset reset Input 1


# 
# connection point avm_dma
# 
add_interface avm_dma avalon start
set_interface_property avm_dma addressUnits WORDS
set_interface_property avm_dma associatedClock clock
set_interface_property avm_dma associatedReset reset
set_interface_property avm_dma bitsPerSymbol 8
set_interface_property avm_dma burstOnBurstBoundariesOnly false
set_interface_property avm_dma burstcountUnits WORDS
set_interface_property avm_dma doStreamReads false
set_interface_property avm_dma doStreamWrites false
set_interface_property avm_dma holdTime 0
set_interface_property avm_dma linewrapBursts false
set_interface_property avm_dma maximumPendingReadTransactions 0
set_interface_property avm_dma maximumPendingWriteTransactions 0
set_interface_property avm_dma readLatency 0
set_interface_property avm_dma readWaitTime 1
set_interface_property avm_dma setupTime 0
set_interface_property avm_dma timingUnits Cycles
set_interface_property avm_dma writeWaitTime 0
set_interface_property avm_dma ENABLED true
set_interface_property avm_dma EXPORT_OF ""
set_interface_property avm_dma PORT_NAME_MAP ""
set_interface_property avm_dma CMSIS_SVD_VARIABLES ""
set_interface_property avm_dma SVD_ADDRESS_GROUP ""

add_interface_port avm_dma avm_dma_address address Output 3
add_interface_port avm_dma avm_dma_write_n write_n Output 1
add_interface_port avm_dma avm_dma_writedata writedata Output 32
add_interface_port avm_dma avm_dma_waitrequest waitrequest Input 1


# 
# connection point interrupt_receiver
# 
add_interface interrupt_receiver interrupt start
set_interface_property interrupt_receiver associatedAddressablePoint ""
set_interface_property interrupt_receiver associatedClock clock
set_interface_property interrupt_receiver associatedReset reset
set_interface_property interrupt_receiver irqScheme INDIVIDUAL_REQUESTS
set_interface_property interrupt_receiver ENABLED true
set_interface_property interrupt_receiver EXPORT_OF ""
set_interface_property interrupt_receiver PORT_NAME_MAP ""
set_interface_property interrupt_receiver CMSIS_SVD_VARIABLES ""
set_interface_property interrupt_receiver SVD_ADDRESS_GROUP ""

add_interface_port interrupt_receiver interrupt_receiver_irq irq Input 1


# 
# connection point conduit
# 
add_interface conduit conduit end
set_interface_property conduit associatedClock clock
set_interface_property conduit associatedReset reset
set_interface_property conduit ENABLED true
set_interface_property conduit EXPORT_OF ""
set_interface_property conduit PORT_NAME_MAP ""
set_interface_property conduit CMSIS_SVD_VARIABLES ""
set_interface_property conduit SVD_ADDRESS_GROUP ""

add_interface_port conduit coe_dma_waitrequest waitrequest Output 1
add_interface_port conduit coe_dma_wraddr wraddr Input 3
add_interface_port conduit coe_dma_wren wren Input 1
add_interface_port conduit coe_dma_wrdata wrdata Input 32
add_interface_port conduit coe_dma_finish_irq finish_irq Output 1

