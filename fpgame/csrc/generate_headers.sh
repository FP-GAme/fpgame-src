#!/bin/sh

# This requires that you add the Qsys rootdir to your path. Note, ALTERA_ROOT must point to your
#   specific install location, which is likely different than mine (mine is not default).
# For example, you can put in your .bashrc or .zshrc or whatever:
# export ALTERA_ROOT="$HOME/Programs/intelFPGA_lite/20.1"
# export QUARTUS_ROOTDIR_OVERRIDE="$ALTERA_ROOT/quartus"
# export QSYS_ROOTDIR="$QUARTUS_ROOTDIR_OVERRIDE/sopc_builder/bin"
# export PATH="$PATH:$QSYS_ROOTDIR"
# export QUARTUS_ROOTDIR=$QUARTUS_ROOTDIR_OVERRIDE

# Most people who installed Quartus on Linux following the tutorials will only have to add the last
#   two lines.

sopc-create-header-files "../fpgame_soc.sopcinfo" --single fpgame_hps.h --module hps_0
