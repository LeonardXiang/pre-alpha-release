# TODO: Define where you want your macros here! Below is the main command that
# you will be using:
#     
#    bsg_place_macro <hier name> <x location> <y location> <orientation = N,S,E,W>
#

bsg_place_macro bp_fe_pc_gen_1/genblk1_branch_prediction_1/btb_1/bsg_mem_1rw_sync_synth_1/macro_mem 1250 1200 FN
bsg_place_macro icache_1/tag_mem/macro_mem 1483.460 1337.440 N
bsg_place_macro icache_1/metadata_mem/macro_mem 1071.105 932.750 FN

set gap 50
set ram_width [get_attribute [get_cell icache_1/data_mem_banks_0__data_mem_bank/macro_mem] height]
set Y 300
set X [expr $ram_width + 450]
for {set i 0} {$i < 8} {incr i} {
  bsg_place_macro icache_1/data_mem_banks_${i}__data_mem_bank/macro_mem $X $Y W 0 0 $gap 3 $gap 3
  set X [expr $X + ($ram_width + $gap)]
}

