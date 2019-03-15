# placement.tcl
#
# This file contains information used by icc to specify placement of
# cell groups or blocks within the floorplan of the chip. This is quite
# difficult to make it prcess independant thus this file is in the
# hardened folder.
#
#   create_bounds -name <object_name> -coordinate { {<llx> <lly>} {<urx> <ury>} } -type <type = soft,hard,exclusive> -cycle_color { hierarchy_regex }
#

# TODO: Place any placement bounds below!

create_placement_blockage -coordinate {{100.0 100.0} {150.0 680.0}} -name placement_blockage_0 -type hard
create_placement_blockage -coordinate {{300.0 100.0} {350.0 680.0}} -name placement_blockage_1 -type hard
create_placement_blockage -coordinate {{500.0 100.0} {550.0 680.0}} -name placement_blockage_2 -type hard
create_placement_blockage -coordinate {{700.0 100.0} {750.0 680.0}} -name placement_blockage_3 -type hard
create_placement_blockage -coordinate {{900.0 100.0} {950.0 680.0}} -name placement_blockage_4 -type hard
create_placement_blockage -coordinate {{1100.0 100.0} {1150.0 680.0}} -name placement_blockage_5 -type hard
create_placement_blockage -coordinate {{1300.0 100.0} {1350.0 680.0}} -name placement_blockage_6 -type hard
create_placement_blockage -coordinate {{1500.0 100.0} {1550.0 680.0}} -name placement_blockage_7 -type hard

create_bounds -name be_checker -coordinate {100.0 700.0 250.0 900.0} -type hard -cycle_color be_checker/*
create_bounds -name be_calculator -coordinate {300.0 800.0 1240.0 1250.0} -type hard -cycle_color be_calculator/*
create_bounds -name be_dcache_stat_mem -coordinate {1300.0 950.0 1500.0 1100.0} -type hard -cycle_color be_mmu/dcache/stat_mem/*
#create_bounds -name be_dcache_stat_mem -coordinate {1450.0 900.0 1700.0 1100.0} -type hard -cycle_color be_mmu/dcache/stat_mem/*

create_fp_placement -timing_driven -effort high

