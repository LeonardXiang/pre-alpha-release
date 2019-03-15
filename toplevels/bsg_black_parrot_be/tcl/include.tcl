# include.tcl
#
# This file defines a list of directories to search for `include files
# required to synthesize and simulate the design.
#


# bsg repo dirs
#
# These envvars define the path to all the cad repos used in the
# flow. These envvars should be set in the  chip repo
# Makefile.design.include file.
#
set BSG_IP_CORES_DIR         $::env(BSG_IP_CORES_DIR)
set BSG_DESIGNS_DIR          $::env(BSG_DESIGNS_DIR)
set BSG_DESIGNS_TARGET_DIR   $::env(BSG_DESIGNS_TARGET_DIR)
set BSG_PACKAGING_DIR        $::env(BSG_PACKAGING_DIR)
set BSG_MANYCORE_DIR         $::env(BSG_MANYCORE_DIR)
set BSG_BLACK_PARROT_DIR     $::env(BSG_BLACK_PARROT_DIR)

set BP_TOP_DIR               $::env(BP_TOP_DIR)
set BP_BE_DIR                $::env(BP_BE_DIR)
set BP_FE_DIR                $::env(BP_FE_DIR)
set BP_ME_DIR                $::env(BP_ME_DIR)
set BP_COMMON_DIR            $::env(BP_COMMON_DIR)

set BP_END                   $::env(BP_END)

# bsg packaging vars
#
# These envvars define while files should be found ensure the correct
# packaging and pinouts are used. These envvars should be set in the
# chip repo Makefile.design.include file.
#
set BSG_PACKAGING_FOUNDRY    $::env(BSG_PACKAGING_FOUNDRY)
set BSG_PINOUT               $::env(BSG_PINOUT)
set BSG_PINOUT_FOUNDRY       $::env(BSG_PINOUT_FOUNDRY)
set BSG_PINOUT_IOPAD_MAPPING $::env(BSG_PINOUT_IOPAD_MAPPING)

# bsg_sverilog_include_paths
#
# DO NOT change the name of this variable. This special variable
# is a list of all include directories needed for the design. Include
# directories are where the tools should look for files that are
# included via the `include command. This is particularly important
# for making sure the packaing and IO cells are correctly instantiated.
#
# Note: we use the 'portable' packaging foundry, even if that is not
#       the target packaging foundry. We do this so that the design
#       will perform RTL simulation. As part of the dc flow, this will
#       be swapped with the correct packaging foundry.
#
# FIXME: potential fix this^^^ caveat to be more intuitive (hard folder swap?)
#
set bsg_sverilog_include_paths [join "
  $BSG_PACKAGING_DIR/common/portable/v
  $BSG_PACKAGING_DIR/pinouts/$BSG_PINOUT/common/v
  $BSG_PACKAGING_DIR/pinouts/$BSG_PINOUT/$BSG_PINOUT_FOUNDRY/v
  $BSG_PACKAGING_DIR/pinouts/$BSG_PINOUT/$BSG_PINOUT_FOUNDRY/v/iopad_mappings/$BSG_PINOUT_IOPAD_MAPPING
"]

set flist [open "$BSG_BLACK_PARROT_DIR/$BP_END/syn/flist.vcs" r]
while { [gets $flist data] >= 0 } {
  set re_incdir [regexp -inline {^\+incdir\+(.*)} $data]
  if { [llength $re_incdir] > 0 } {
    eval "set inc_dir [lindex $re_incdir 1]"
    lappend bsg_sverilog_include_paths "${inc_dir}"
  }
}
close $flist

