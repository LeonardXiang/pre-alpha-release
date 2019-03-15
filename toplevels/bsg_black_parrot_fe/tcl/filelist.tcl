# filelist.tcl
#
# This file defines a list of all files required to synthesize
# and simulate the design.
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

# bsg_sverilog_source_files
#
# DO NOT change the name of this variable. This special variable
# is a list of all verilog files needed for the design. The order
# is the order they are elaborated, therefore 'header' verilog
# files should be higher up the list to ensure their definitions
# are elaborated before they are referenced.
#
set bsg_sverilog_source_files [list]

set flist [open "$BSG_BLACK_PARROT_DIR/$BP_END/syn/flist.vcs" r]
while { [gets $flist data] >= 0 } {

  if { [regexp {^#.*}            $data] } { continue }
  if { [regexp {^\+incdir\+(.*)} $data] } { continue }

  eval "set src_file $data"
  lappend bsg_sverilog_source_files $src_file

}
close $flist

