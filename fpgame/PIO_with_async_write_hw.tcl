# TCL File Generated by Component Editor 20.1
# Sun Apr 11 18:16:50 EDT 2021
# DO NOT MODIFY


# 
# PIO_with_async_write "PIO for those who aren't insane" v4.20
#  2021.04.11.18:16:50
# 
# 

# 
# request TCL package from ACDS 16.1
# 
package require -exact qsys 16.1


# 
# module PIO_with_async_write
# 
set_module_property DESCRIPTION ""
set_module_property NAME PIO_with_async_write
set_module_property VERSION 4.20
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property AUTHOR ""
set_module_property DISPLAY_NAME "PIO for those who aren't insane"
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property REPORT_TO_TALKBACK false
set_module_property ALLOW_GREYBOX_GENERATION false
set_module_property REPORT_HIERARCHY false


# 
# file sets
# 
add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL pio_async_write
set_fileset_property QUARTUS_SYNTH ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property QUARTUS_SYNTH ENABLE_FILE_OVERWRITE_MODE false
add_fileset_file pio_async_write.v VERILOG PATH src/pio_async_write.v TOP_LEVEL_FILE

add_fileset SIM_VERILOG SIM_VERILOG "" ""
set_fileset_property SIM_VERILOG TOP_LEVEL pio_async_write
set_fileset_property SIM_VERILOG ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property SIM_VERILOG ENABLE_FILE_OVERWRITE_MODE true
add_fileset_file pio_async_write.v VERILOG PATH src/pio_async_write.v


# 
# parameters
# 


# 
# display items
# 


# 
# connection point avs_s0
# 
add_interface avs_s0 avalon end
set_interface_property avs_s0 addressUnits WORDS
set_interface_property avs_s0 associatedClock clock
set_interface_property avs_s0 associatedReset reset
set_interface_property avs_s0 bitsPerSymbol 8
set_interface_property avs_s0 bridgedAddressOffset 0
set_interface_property avs_s0 burstOnBurstBoundariesOnly false
set_interface_property avs_s0 burstcountUnits WORDS
set_interface_property avs_s0 explicitAddressSpan 0
set_interface_property avs_s0 holdTime 0
set_interface_property avs_s0 linewrapBursts false
set_interface_property avs_s0 maximumPendingReadTransactions 0
set_interface_property avs_s0 maximumPendingWriteTransactions 0
set_interface_property avs_s0 readLatency 0
set_interface_property avs_s0 readWaitTime 1
set_interface_property avs_s0 setupTime 0
set_interface_property avs_s0 timingUnits Cycles
set_interface_property avs_s0 writeWaitTime 0
set_interface_property avs_s0 ENABLED true
set_interface_property avs_s0 EXPORT_OF ""
set_interface_property avs_s0 PORT_NAME_MAP ""
set_interface_property avs_s0 CMSIS_SVD_VARIABLES ""
set_interface_property avs_s0 SVD_ADDRESS_GROUP ""

add_interface_port avs_s0 avs_s0_address address Input 2
add_interface_port avs_s0 avs_s0_write write Input 1
add_interface_port avs_s0 avs_s0_writedata writedata Input 32
set_interface_assignment avs_s0 embeddedsw.configuration.isFlash 0
set_interface_assignment avs_s0 embeddedsw.configuration.isMemoryDevice 0
set_interface_assignment avs_s0 embeddedsw.configuration.isNonVolatileStorage 0
set_interface_assignment avs_s0 embeddedsw.configuration.isPrintableDevice 0


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
# connection point conduit_end
# 
add_interface conduit_end conduit end
set_interface_property conduit_end associatedClock clock
set_interface_property conduit_end associatedReset ""
set_interface_property conduit_end ENABLED true
set_interface_property conduit_end EXPORT_OF ""
set_interface_property conduit_end PORT_NAME_MAP ""
set_interface_property conduit_end CMSIS_SVD_VARIABLES ""
set_interface_property conduit_end SVD_ADDRESS_GROUP ""

add_interface_port conduit_end write_valid export_valid Output 1
add_interface_port conduit_end write_data export_data Output 32

