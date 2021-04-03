# TCL File Generated by Component Editor 20.1
# Sat Mar 20 22:36:31 EDT 2021
# DO NOT MODIFY


# 
# h2f_vram_interface "H2F VRAM Interface" v1.0
#  2021.03.20.22:36:31
# 
# 

# 
# request TCL package from ACDS 16.1
# 
package require -exact qsys 16.1


# 
# module h2f_vram_interface
# 
set_module_property DESCRIPTION ""
set_module_property NAME h2f_vram_interface
set_module_property VERSION 1.0
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property AUTHOR ""
set_module_property DISPLAY_NAME "H2F VRAM Interface"
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property REPORT_TO_TALKBACK false
set_module_property ALLOW_GREYBOX_GENERATION false
set_module_property REPORT_HIERARCHY false


# 
# file sets
# 
add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL h2f_vram_interface
set_fileset_property QUARTUS_SYNTH ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property QUARTUS_SYNTH ENABLE_FILE_OVERWRITE_MODE false
add_fileset_file h2f_vram_interface.sv SYSTEM_VERILOG PATH src/ppu/h2f_vram_interface.sv TOP_LEVEL_FILE


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

add_interface_port avs_s0 avs_s0_address address Input 13
add_interface_port avs_s0 avs_s0_write write Input 1
add_interface_port avs_s0 avs_s0_writedata writedata Input 64
add_interface_port avs_s0 avs_s0_byteenable byteenable Input 8
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
# connection point external
# 
add_interface external conduit end
set_interface_property external associatedClock clock
set_interface_property external associatedReset ""
set_interface_property external ENABLED true
set_interface_property external EXPORT_OF ""
set_interface_property external PORT_NAME_MAP ""
set_interface_property external CMSIS_SVD_VARIABLES ""
set_interface_property external SVD_ADDRESS_GROUP ""

add_interface_port external coe_hps_vram_wraddr export_wraddr Output 13
add_interface_port external coe_hps_vram_wren export_wren Output 1
add_interface_port external coe_hps_vram_wrdata export_wrdata Output 64
add_interface_port external coe_hps_vram_byteena export_byteena Output 8


# 
# connection point ppu_transfer_irq
# 
add_interface ppu_transfer_irq interrupt end
set_interface_property ppu_transfer_irq associatedAddressablePoint avs_s0
set_interface_property ppu_transfer_irq associatedClock clock
set_interface_property ppu_transfer_irq associatedReset reset
set_interface_property ppu_transfer_irq bridgedReceiverOffset 0
set_interface_property ppu_transfer_irq bridgesToReceiver ""
set_interface_property ppu_transfer_irq ENABLED true
set_interface_property ppu_transfer_irq EXPORT_OF ""
set_interface_property ppu_transfer_irq PORT_NAME_MAP ""
set_interface_property ppu_transfer_irq CMSIS_SVD_VARIABLES ""
set_interface_property ppu_transfer_irq SVD_ADDRESS_GROUP ""

add_interface_port ppu_transfer_irq ins_irq0_irq irq Output 1


#
# Device Tree Generation
#
set_module_assignment embeddedsw.dts.vendor "dsa"
set_module_assignment embeddedsw.dts.compatible "dev,h2f_vram_interface"
set_module_assignment embeddedsw.dts.group "h2f_vram_interface"