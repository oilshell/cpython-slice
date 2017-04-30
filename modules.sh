#!/bin/bash
#
# Usage:
#   ./modules.sh <function name>

set -o nounset
set -o pipefail
set -o errexit

source common.sh

# Data flow
#
# ./module_manifest.py -> c_module_manifest.json or .txt
#   Or maybe this is only for C modules?
#   os.path -> posixpath.pyc
#
# ./default_modules.py -> DEFAULT.py-stdlib.txt
#                         DEFAULT.c-stdlib.txt
#

# ./py_deps.py hello   -> hello.py-stdlib.txt
#                         hello.c-stdlib.txt

# Need to fix osh.asdl issue
# ./py_deps.py bin.oil  -> oil.{py,c}-stdlib.txt.txt
#
# Need to fix byterun issue
# ./py_deps.py bin.opy_  -> opy.{py,c}-stdlib.txt.txt
#
# These are module names and filenames or what?
#
# For the modules that end with .so
#
# Build process:
# py files: join {DEFAULT,hello}.py-stdlib.txt.  Compile .pyc and copy.
# c files: join {DEFAULT,hello}.c-stdlib.txt.  Output a text file for slice.sh
# to take as additional input.
# - Also need to rewrite config.c.
#
# how about gen_module_init.py -> sed -> config.c
# Or this might be awk too.

# Cases:
# json module: Lib/json/*.py

# Should you write your own Makefile for this?  Sounds like it.  Would be
# another good use case.
#
# I guess it should be ~/git/oil/Makefile
#
# ~/git/oil/
#    Makefile
#    ovm/
#      ovm.mk  # Makefile fragment
#      common.sh
#      bundle.sh
#      coverage.sh
#      modules.sh
#      perftools.sh
#      slice.sh
#      testdata/
#        hello_minimal.py
#        hello.py  - optparse, json, fcntl, etc.
#    Python-2.7.13/
#
# All OVM bundles:
#
# make _bin/hello
# make _bin/oil
# make _bin/opy

# make _bin/ovm  -- this is the standalone guy I guess.
#
# Problems: CFLAGS for variants and so forth.
# You would need eval, like in bwk.
#
# make _bin/hello_dbg
# make _bin/oil_dbg
# make _bin/ovm_dbg
# make _bin/ovm_cov
# make _bin/ovm_asan

list() {
  pushd $PY27
  ../module_manifest.py
  popd
}

# This has Python paths, but no C paths!
base-modules() {
  $PY27/python -S ./base_modules.py 
}

"$@"
