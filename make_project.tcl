# ==================================================================================================
# make_project.tcl
#
# Simple script for creating a vivado project from the project/ folder of the Pavel Demin's  
# red-pitaya-notes-master/ git project
#
# Make sure the script is run from the red-pitaya-notes-master/ folder
#
# by Anton Potocnik, 02.10.2016 - 05.10.2016
# ==================================================================================================

set project_name "1_led_blink"
#set project_name "2_knight_rider"
#set project_name "3_timing_knight_rider"

source projects/$project_name/block_design.tcl

