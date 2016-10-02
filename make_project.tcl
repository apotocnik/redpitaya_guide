# ==================================================================================================
# make_project.tcl
#
# Simple script for creating a vivado project from the project/ folder of the Pavel Demin's  
# red-pitaya-notes-master/ git project
#
# Make sure the script is run from the red-pitaya-notes-master/ folder
#
# by Anton Potocnik, 02.10.2016
# ==================================================================================================

set project_name "led_blinker"

set part_name "xc7z010clg400-1"

set argv "$project_name $part_name"

source scripts/project.tcl

