#!/bin/bash
#
# Usage:
#   ./slice.sh <function name>

set -o nounset
set -o pipefail
set -o errexit

source common.sh


# Generate config.c.  TODO: Replace this with Python?
#
# -c : means generate config.
#
# algorithm:
# while read line
# MODS="$MODS $mods"

#MODS
# Modules/config.c.in
# /MARKER 1/i$NL$EXTDECLS
# /MARKER 2/i$NL$INITBITS
#
# single module list with declarations and initialization
#
# I think what you want to do is:
# - generate a module names list from running OSH
# - generate module names -> filenames, foo.py, foomodule.c, _foo.c
#   - this goes into module-sources.txt
# - generate config.c.  I guess we can reuse makesetup.c, unless we can get
#   rid of the other parts.  I honestly
#   - this only depends on the names of the modules
#
# "Convert templates into Makefile and config.c, based on the module
# definitions found in the file Setup."
# OK I am actually subsuming this.  hm.

# init_builtin(name) goes through PyImport_Inittab().  It does a LINEAR
# SEARCH with strcmp().  Gets called on FIRST IMPORT I believe.
#
# This is imp.init_builtin -- when does it get called?

mod-setup() {
  local out=${1:-$PY27/Modules/config.c}

  local abs_out=$PWD/$out

  pushd $PY27

  cp -v ../ModulesSetup Modules/Setup

	Modules/makesetup \
    -c Modules/config.c.in \
		-s Modules \
		Modules/Setup.config \
		Modules/Setup.local \
		Modules/Setup
  popd

  # Is this for atomic mv?
  mv -v $PY27/config.c $abs_out
}

# Why is this bigger than python?
#
# Does the intermediate .ar or ranlib do stuff?  But I thought the old ovm had
# that too.  No that 'generates an index to speed up access to archives'.

# 5.5 seconds to build.  Not too bad.  Will probabl take 10-15 seconds on
# slower machines though.
debug-ovm2() {
  gdb --tui --args $PY27/ovm2 "$@"
}

test-oil() {
  _OVM_RUN_SELF=0 $PY27/ovm2 ~/git/oil/opy/_tmp/oil.zip
}

readonly GPERF_LIBS=$PWD/_tmp/gperftools-2.5/.libs 

# Build with the profiling library
build-gperf() {
  build -L $GPERF_LIBS -l profiler
}

run-gperf() {
  mkdir -p _gperf

  local out=_gperf/hello.prof
  LD_LIBRARY_PATH=$GPERF_LIBS \
  CPUPROFILE=$out \
    ./run.sh test-hello $PY27/ovm2

  ls -l $out
}

gperf-report() {
  ./gperftools.sh pprof --text $PY27/ovm2 _gperf/hello.prof
}

#
# Heap
#

# Build with the profiling library
build-hprof() {
  build -L $GPERF_LIBS -l tcmalloc
}

run-hprof() {
  mkdir -p _gperf

  local out=_gperf/hello.hprof
  LD_LIBRARY_PATH=$GPERF_LIBS \
  HEAPPROFILE=$out \
    ./run.sh test-hello $PY27/ovm2

  # Suffix
  ls -l $out*
}

# pprof bug: if you specify a file that doesn't exist, it tries to download
# stuff from the web!
# # Interesting, on hello.py: dictresize, Py_SetItem, etc.
hprof-report() {
  set -x
  ./gperftools.sh pprof --text $PY27/ovm2 $PWD/_gperf/hello.hprof*
}

test-hello() {
  ./run.sh test-hello $PY27/ovm2
}


"$@"
