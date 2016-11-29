
# ==================================================================================================
# block_design.tcl - Create Vivado Project - 4_averager
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

# BRAM controller
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.0 axi_bram_ctrl_0
set_property -dict [list CONFIG.SINGLE_PORT_BRAM {1}] [get_bd_cells axi_bram_ctrl_0]
endgroup

# BRAM generator
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.3 blk_mem_gen_0
set_property -dict [list CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Enable_32bit_Address {true} CONFIG.Operating_Mode_B {READ_FIRST} CONFIG.Register_PortA_Output_of_Memory_Primitives {false} CONFIG.Register_PortB_Output_of_Memory_Primitives {false} CONFIG.use_bram_block {Stand_Alone} CONFIG.Use_Byte_Write_Enable {true} CONFIG.Byte_Size {8} CONFIG.Enable_B {Always_Enabled} CONFIG.Use_RSTA_Pin {false} CONFIG.Use_RSTB_Pin {true} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100}] [get_bd_cells blk_mem_gen_0]
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


# ====================================================================================
# RTL modules

# signal route
create_bd_cell -type module -reference signal_route signal_route_0


# averager
create_bd_cell -type module -reference averager averager_0

# expTwo
create_bd_cell -type module -reference expTwo expTwo_0
create_bd_cell -type module -reference expTwo expTwo_1

# selector for the trigger
create_bd_cell -type module -reference selector selector_0


# ====================================================================================
# Connections 

# signal route
connect_bd_net [get_bd_pins signal_route_0/data_in] [get_bd_pins axis_red_pitaya_adc_0/m_axis_tdata]


# Averager
connect_bd_net [get_bd_pins signal_route_0/data_o1] [get_bd_pins averager_0/data_in]
connect_bd_net [get_bd_pins averager_0/clk] [get_bd_pins axis_red_pitaya_adc_0/adc_clk]
connect_bd_net [get_bd_pins averager_0/addr] [get_bd_pins blk_mem_gen_0/addrb]
connect_bd_net [get_bd_pins averager_0/data_w] [get_bd_pins blk_mem_gen_0/dinb]
connect_bd_net [get_bd_pins averager_0/we] [get_bd_pins blk_mem_gen_0/web]
connect_bd_net [get_bd_pins blk_mem_gen_0/clkb] [get_bd_pins axis_red_pitaya_adc_0/adc_clk]
connect_bd_net [get_bd_pins averager_0/data_r] [get_bd_pins blk_mem_gen_0/doutb]
connect_bd_net [get_bd_pins selector_0/S] [get_bd_pins averager_0/trig]
# to GPIO
connect_bd_net [get_bd_pins xls_NAVERAGES/Dout] [get_bd_pins expTwo_1/log2N]
connect_bd_net [get_bd_pins xls_NSAMPLES/Dout] [get_bd_pins expTwo_0/log2N]
connect_bd_net [get_bd_pins expTwo_0/N] [get_bd_pins averager_0/nsamples]
connect_bd_net [get_bd_pins expTwo_1/N] [get_bd_pins averager_0/naverages]
connect_bd_net [get_bd_pins xls_reset/Dout] [get_bd_pins averager_0/reset]


# BRAM controller
connect_bd_intf_net [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA] [get_bd_intf_pins blk_mem_gen_0/BRAM_PORTA]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/processing_system7_0/M_AXI_GP0" Clk "Auto" }  [get_bd_intf_pins axi_bram_ctrl_0/S_AXI]


# GPIO_0 Port1
connect_bd_net [get_bd_pins axi_gpio_0/gpio_io_i] [get_bd_pins axi_gpio_0/gpio_io_o]
connect_bd_net [get_bd_pins xls_NAVERAGES/Din] [get_bd_pins axi_gpio_0/gpio_io_o]
connect_bd_net [get_bd_pins xls_NSAMPLES/Din] [get_bd_pins axi_gpio_0/gpio_io_o]
connect_bd_net [get_bd_pins xls_reset/Din] [get_bd_pins axi_gpio_0/gpio_io_o]
connect_bd_net [get_bd_pins xls_trigger/Din] [get_bd_pins axi_gpio_0/gpio_io_o]

# GPIO_0 Port2
connect_bd_net [get_bd_pins xlconcat_1/dout] [get_bd_pins axi_gpio_0/gpio2_io_i]
connect_bd_net [get_bd_pins xlconcat_1/In0] [get_bd_pins averager_0/finished]
connect_bd_net [get_bd_pins xlconstant_0/dout] [get_bd_pins xlconcat_1/In1]

# Trigger
connect_bd_net [get_bd_pins c_counter_binary_0/CLK] [get_bd_pins axis_red_pitaya_adc_0/adc_clk]
connect_bd_net [get_bd_pins c_counter_binary_0/Q] [get_bd_pins selector_0/A]
connect_bd_net [get_bd_pins xls_trigger/Dout] [get_bd_pins selector_0/div]

# Concatenation for LEDs
connect_bd_net [get_bd_ports led_o] [get_bd_pins xlconcat_0/dout]
connect_bd_net [get_bd_pins xlconcat_0/In0] [get_bd_pins averager_0/finished]
connect_bd_net [get_bd_pins xlconcat_0/In1] [get_bd_pins averager_0/averages]



# ====================================================================================
# Hierarchies

group_bd_cells SignalGenerator [get_bd_cells axis_red_pitaya_dac_0] [get_bd_cells dds_compiler_0] [get_bd_cells clk_wiz_0]

group_bd_cells Trigger [get_bd_cells selector_0] [get_bd_cells c_counter_binary_0]

group_bd_cells IO_Settings [get_bd_cells xls_NSAMPLES] [get_bd_cells xls_NAVERAGES] [get_bd_cells xls_reset] [get_bd_cells xlconcat_1] [get_bd_cells axi_gpio_0] [get_bd_cells expTwo_0] [get_bd_cells expTwo_1] [get_bd_cells xls_trigger] [get_bd_cells xlconstant_0]

group_bd_cells Averager [get_bd_cells averager_0] [get_bd_cells blk_mem_gen_0] [get_bd_cells axi_bram_ctrl_0]



# ====================================================================================
# Addresses
set_property range 4K [get_bd_addr_segs {processing_system7_0/Data/SEG_axi_bram_ctrl_0_Mem0}]
