# ==================================================================================================
# make_project.tcl
#
# Simple script for creating a Vivado project from the project/ folder 
# Based on Pavel Demin's red-pitaya-notes-master/ git project
#
# Make sure the script is executed from redpitaya_guide/ folder
#
# by Anton Potocnik, 02.10.2016 - 29.11.2016
# ==================================================================================================

set project_name "1_led_blink"
#set project_name "2_knight_rider"
#set project_name "3_stopwatch"
#set project_name "4_averager"

source projects/$project_name/block_design.tcl

