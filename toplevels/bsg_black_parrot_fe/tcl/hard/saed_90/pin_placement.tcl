# pin_placement.tcl
#
# In this file, you can define where you would like the pins to be placed
# in the floorplan.

#set_pin_physical_constraints -pin_name { <PIN NAME> } -layers { <METAL LAYERS> } -width 0.16 -depth 0.16 -side <1,2,3, or 4> -offset <MICRONS>

set_attribute [get_ports] is_fixed false
place_fp_pins -block_level

