
# ==================================================================================================
# block_design.tcl - Create Vivado Project - 5_averager
#
# This script should be run from the base redpitaya-guides/ folder inside Vivado tcl console.
#
# This script is modification of Pavel Demin's project.tcl and block_design.tcl files
# by Anton Potocnik, 29.11.2016
# Tested with Vivado 2016.3
# ==================================================================================================

# Create basic Red Pitaya Block Design
source projects/$project_name/basic_red_pitaya_bd.tcl



# ====================================================================================
# IP cores

# GPIO_0
set_property -dict [list CONFIG.C_TRI_DEFAULT_2 {0xFFFFFF00} CONFIG.C_ALL_INPUTS_2 {0}] [get_bd_cells axi_gpio_0]

# AXI BRAM Reader
startgroup
create_bd_cell -type ip -vlnv anton-potocnik:user:axi_bram_reader:1.0 axi_bram_reader_0
endgroup

# AXIS Averager
startgroup
create_bd_cell -type ip -vlnv anton-potocnik:user:axis_averager:1.0 axis_averager_0
endgroup

# BRAM Switch
startgroup
create_bd_cell -type ip -vlnv anton-potocnik:user:bram_switch:1.0 bram_switch_0
endgroup

# BRAM generator
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.3 blk_mem_gen_0
set_property -dict [list CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Enable_32bit_Address {false} CONFIG.Operating_Mode_B {READ_FIRST} CONFIG.Register_PortA_Output_of_Memory_Primitives {false} CONFIG.Register_PortB_Output_of_Memory_Primitives {false} CONFIG.use_bram_block {Stand_Alone} CONFIG.Use_Byte_Write_Enable {false} CONFIG.Byte_Size {8} CONFIG.Enable_B {Always_Enabled} CONFIG.Use_RSTA_Pin {false} CONFIG.Use_RSTB_Pin {false} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.Write_Depth_A {1024} CONFIG.Enable_A {Always_Enabled}  CONFIG.Use_RSTB_Pin {false} ] [get_bd_cells blk_mem_gen_0] 
endgroup


# xlslices
startgroup
# slice_reset
create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xls_reset
set_property -dict [list CONFIG.DIN_TO {0} CONFIG.DIN_FROM {0}] [get_bd_cells xls_reset]

# slice_trigger
create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xls_trigger
set_property -dict [list CONFIG.DIN_TO {8} CONFIG.DIN_FROM {15}] [get_bd_cells xls_trigger]

# slice_NSAMPLES
create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xls_NSAMPLES
set_property -dict [list CONFIG.DIN_TO {16} CONFIG.DIN_FROM {23}] [get_bd_cells xls_NSAMPLES]

# slice_NAVERAGES
create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xls_NAVERAGES
set_property -dict [list CONFIG.DIN_TO {24} CONFIG.DIN_FROM {31}] [get_bd_cells xls_NAVERAGES]
endgroup


# Binary Counter - 32bit
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:c_counter_binary:12.0 c_counter_binary_0
set_property -dict [list CONFIG.Output_Width {32}] [get_bd_cells c_counter_binary_0]
endgroup


# Concatenation for LEDs
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_0
set_property -dict [list CONFIG.IN1_WIDTH.VALUE_SRC USER CONFIG.IN0_WIDTH.VALUE_SRC USER] [get_bd_cells xlconcat_0]
set_property -dict [list CONFIG.IN1_WIDTH {7}] [get_bd_cells xlconcat_0]

create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_1
set_property -dict [list CONFIG.IN0_WIDTH.VALUE_SRC USER CONFIG.IN1_WIDTH.VALUE_SRC USER] [get_bd_cells xlconcat_1]
set_property -dict [list CONFIG.IN1_WIDTH {31}] [get_bd_cells xlconcat_1]
endgroup


# Constant for GPIO Port 2 input
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0
set_property -dict [list CONFIG.CONST_WIDTH {31} CONFIG.CONST_VAL {0}] [get_bd_cells xlconstant_0]
endgroup


# Constant for AXIS aresetn
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlc_reset
endgroup


# ====================================================================================
# RTL modules

# signal split
create_bd_cell -type module -reference signal_split signal_split_0



# expTwo
create_bd_cell -type module -reference expTwo expTwo_0
create_bd_cell -type module -reference expTwo expTwo_1

# selector for the trigger
create_bd_cell -type module -reference selector selector_0


# ====================================================================================
# Connections 

# signal split
connect_bd_intf_net [get_bd_intf_pins signal_split_0/S_AXIS] [get_bd_intf_pins axis_red_pitaya_adc_0/M_AXIS]


# Averager
connect_bd_intf_net [get_bd_intf_pins axis_averager_0/BRAM_PORTA] [get_bd_intf_pins blk_mem_gen_0/BRAM_PORTA]
connect_bd_intf_net [get_bd_intf_pins bram_switch_0/BRAM_PORTC] [get_bd_intf_pins blk_mem_gen_0/BRAM_PORTB]
connect_bd_intf_net [get_bd_intf_pins axis_averager_0/BRAM_PORTB] [get_bd_intf_pins bram_switch_0/BRAM_PORTB]
connect_bd_intf_net [get_bd_intf_pins axi_bram_reader_0/BRAM_PORTA] [get_bd_intf_pins bram_switch_0/BRAM_PORTA]
connect_bd_net [get_bd_pins axis_averager_0/trig] [get_bd_pins selector_0/S]
connect_bd_net [get_bd_pins axis_averager_0/aclk] [get_bd_pins axis_red_pitaya_adc_0/adc_clk]
connect_bd_net [get_bd_pins axis_averager_0/nsamples] [get_bd_pins expTwo_0/N]
connect_bd_net [get_bd_pins axis_averager_0/naverages] [get_bd_pins expTwo_1/N]
connect_bd_net [get_bd_pins axis_averager_0/user_reset] [get_bd_pins xls_reset/Dout]
connect_bd_net [get_bd_pins axis_averager_0/finished] [get_bd_pins xlconcat_0/In0]
connect_bd_net [get_bd_pins axis_averager_0/averages_out] [get_bd_pins xlconcat_0/In1]
connect_bd_net [get_bd_pins bram_switch_0/switch] [get_bd_pins axis_averager_0/finished]
connect_bd_net [get_bd_pins xlc_reset/dout] [get_bd_pins axis_averager_0/aresetn]
connect_bd_intf_net [get_bd_intf_pins signal_split_0/M_AXIS_PORT1] [get_bd_intf_pins axis_averager_0/S_AXIS]


# to GPIO
connect_bd_net [get_bd_pins xls_NAVERAGES/Dout] [get_bd_pins expTwo_1/log2N]
connect_bd_net [get_bd_pins xls_NSAMPLES/Dout] [get_bd_pins expTwo_0/log2N]
#connect_bd_net [get_bd_pins xls_reset/Dout] [get_bd_pins axis_averager_0/reset]


# AXI BRAM Reader
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/processing_system7_0/M_AXI_GP0" Clk "Auto" }  [get_bd_intf_pins axi_bram_reader_0/S_AXI]


# GPIO_0 Port1
connect_bd_net [get_bd_pins axi_gpio_0/gpio_io_i] [get_bd_pins axi_gpio_0/gpio_io_o]
connect_bd_net [get_bd_pins xls_NAVERAGES/Din] [get_bd_pins axi_gpio_0/gpio_io_o]
connect_bd_net [get_bd_pins xls_NSAMPLES/Din] [get_bd_pins axi_gpio_0/gpio_io_o]
connect_bd_net [get_bd_pins xls_reset/Din] [get_bd_pins axi_gpio_0/gpio_io_o]
connect_bd_net [get_bd_pins xls_trigger/Din] [get_bd_pins axi_gpio_0/gpio_io_o]

# GPIO_0 Port2
connect_bd_net [get_bd_pins xlconcat_1/dout] [get_bd_pins axi_gpio_0/gpio2_io_i]
connect_bd_net [get_bd_pins xlconcat_1/In0] [get_bd_pins axis_averager_0/finished]
connect_bd_net [get_bd_pins xlconstant_0/dout] [get_bd_pins xlconcat_1/In1]

# Trigger
connect_bd_net [get_bd_pins c_counter_binary_0/CLK] [get_bd_pins axis_red_pitaya_adc_0/adc_clk]
connect_bd_net [get_bd_pins c_counter_binary_0/Q] [get_bd_pins selector_0/A]
connect_bd_net [get_bd_pins xls_trigger/Dout] [get_bd_pins selector_0/div]

# Concatenation for LEDs
connect_bd_net [get_bd_ports led_o] [get_bd_pins xlconcat_0/dout]
#connect_bd_net [get_bd_pins xlconcat_0/In0] [get_bd_pins axis_averager_0/finished]
#connect_bd_net [get_bd_pins xlconcat_0/In1] [get_bd_pins axis_averager_0/averages]



# ====================================================================================
# Hierarchies

group_bd_cells SignalGenerator [get_bd_cells axis_red_pitaya_dac_0] [get_bd_cells dds_compiler_0] [get_bd_cells clk_wiz_0]

group_bd_cells Trigger [get_bd_cells selector_0] [get_bd_cells c_counter_binary_0] [get_bd_cells xls_trigger]

group_bd_cells GPIO [get_bd_cells xlconcat_1] [get_bd_cells axi_gpio_0] [get_bd_cells xlconstant_0]

group_bd_cells Averager [get_bd_cells xls_NAVERAGES] [get_bd_cells xls_reset] [get_bd_cells axis_averager_0] [get_bd_cells xls_NSAMPLES] [get_bd_cells expTwo_0] [get_bd_cells blk_mem_gen_0] [get_bd_cells bram_switch_0] [get_bd_cells expTwo_1] [get_bd_cells xlc_reset] [get_bd_cells axi_bram_reader_0]

group_bd_cells PS7 [get_bd_cells processing_system7_0] [get_bd_cells rst_ps7_0_125M] [get_bd_cells ps7_0_axi_periph]


# ====================================================================================
# Addresses
set_property offset 0x40000000 [get_bd_addr_segs {PS7/processing_system7_0/Data/SEG_axi_bram_reader_0_reg0}]
set_property range 4K [get_bd_addr_segs {PS7/processing_system7_0/Data/SEG_axi_bram_reader_0_reg0}]