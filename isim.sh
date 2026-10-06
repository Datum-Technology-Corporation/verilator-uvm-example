#!/usr/bin/env bash
# Build and run this bench with iSim (True North Silicon).
#
# iSim is a SystemVerilog + VHDL simulator that SHIPS a pre-compiled UVM
# library: `-uvm [version]` maps it out of the install's own
# lib/isim/uvm/<version>/ into the work library and resolves uvm_macros.svh
# from the shipped flattened header.  So this script drops exactly what the
# README's verilator line needs and iSim does not:
#
#   $UVM_HOME/uvm_pkg.sv   -- the UVM source itself, replaced by -uvm
#   +incdir+$UVM_HOME      -- its include path, replaced by -uvm
#   +define+UVM_NO_DPI     -- a Verilator capability workaround; iSim's UVM
#                             DPI surface is real, so the bench is built
#                             WITH DPI rather than around it
#
# Everything else is upstream's own: the same two explicit sources in the
# same order, and `+incdir+$(pwd)` so the nine .svh class files `include
# from sig_pkg.sv resolve.  ONE file is added: sig_if.sv.  Verilator finds the
# `sig_if` interface by searching its +incdir directories for a file named after
# the missing module; iSim (like VCS, Questa and dsim) compiles only the sources
# it is given -- +incdir only affects `include -- so without it elaboration
# stops with "Unknown module type: sig_if".
#
# UVM_HOME is never read.  There is nothing to download.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
work="${ISIM_WORK:-$here/isim_work}"
top="${ISIM_TOP:-tbench_top}"
test_name="${UVM_TESTNAME:-sig_model_test}"

isim_vlog="${ISIM_VLOG:-isim-vlog}"
isim_elab="${ISIM_ELAB:-isim-elab}"
isim_run="${ISIM:-isim}"

mkdir -p "$work"

# analyse -- upstream's two explicit sources plus the interface Verilator finds
# by itself, and upstream's own include path
"$isim_vlog" -work "$work" -lib work -uvm \
    "+incdir+$here" \
    "$here/sig_if.sv" "$here/sig_pkg.sv" "$here/tb.sv"

# elaborate -- -sir lowers, compiles and links the native image
"$isim_elab" -work "$work" -lib work -uvm -top "$top" -sir

# run
"$isim_run" -work "$work" -lib work -uvm -top "$top" "+UVM_TESTNAME=$test_name"
