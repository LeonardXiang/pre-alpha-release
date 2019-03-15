# filelist_deltas.tcl
#
# This file contains variables that will change the files used in synthesis
# and hardened simulations. Changes include the ability to swap modules,
# add new sverilog files, and add netlist (pre-compiled) files.
#


# bsg repo dirs
#
# These envvars define the path to all the cad repos used in the
# flow. These envvars should be set in the  chip repo
# Makefile.design.include file.
#
set bsg_chip_dir             $::env(BSG_CHIP_DIR)
set bsg_ip_cores_dir         $::env(BSG_IP_CORES_DIR)
set bsg_designs_dir          $::env(BSG_DESIGNS_DIR)
set bsg_designs_target_dir   $::env(BSG_DESIGNS_TARGET_DIR)
set bsg_packaging_dir        $::env(BSG_PACKAGING_DIR)


# bsg packaging vars
#
# These envvars define while files should be found ensure the correct
# packaging and pinouts are used. These envvars should be set in the
# chip repo Makefile.design.include file.
#
set bsg_packaging_foundry    $::env(BSG_PACKAGING_FOUNDRY)
set bsg_pinout               $::env(BSG_PINOUT)
set bsg_pinout_foundry       $::env(BSG_PINOUT_FOUNDRY)
set bsg_pinout_iopad_mapping $::env(BSG_PINOUT_IOPAD_MAPPING)


# bsg_hard_swap_source_files
#
# DO NOT change the name of this variable. This special variable
# is a list of all verilog files that will swap with files in
# bsg_sverilog_source_files (defined in filelist.tcl). Note: swaps
# are based on the name of the file, therefore, the file being
# swapped in must have the same name as the replaced file.
#

# TODO: Add modules you want to "hard swap" here
set bsg_hard_swap_source_files [join "
    ${bsg_ip_cores_dir}/hard/saed_90/bsg_misc/bsg_mux2_gatestack.v
    ${bsg_ip_cores_dir}/hard/saed_90/bsg_misc/bsg_dff_gatestack.v
    ${bsg_ip_cores_dir}/hard/saed_90/bsg_mem/bsg_mem_1r1w_sync.v
    ${bsg_ip_cores_dir}/hard/saed_90/bsg_mem/bsg_mem_1r1w.v
    ${bsg_ip_cores_dir}/hard/saed_90/bsg_mem/bsg_mem_1rw_sync_mask_write_bit.v
    ${bsg_ip_cores_dir}/hard/saed_90/bsg_mem/bsg_mem_1rw_sync_mask_write_byte.v
    ${bsg_ip_cores_dir}/hard/saed_90/bsg_mem/bsg_mem_1rw_sync.v
"]


# bsg_new_sverilog_source_files
#
# DO NOT change the name of this variable. This special variable
# is a list of new sverilog files that are required for synthesis
# or hardened simulations. This list will be appended to the end
# of the normal file list.
#
set bsg_new_sverilog_source_files [join "
"]


# bsg_netlist_source_files
#
# DO NOT change the name of this variable. This special variable
# is a list of pre-compiled netlist files. These files will not
# be synthesized and a dont_touch modifier will be applied to
# make sure the dc does not optimize them.
#

set bsg_netlist_source_files [join "
"]

