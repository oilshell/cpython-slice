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

list() {
  pushd $PY27
  echo Lib/*.py
  echo Modules/*.c
  popd
}

list2() {
  pushd $PY27
  ../module_manifest.py
  popd
}

# This has Python paths, but no C paths!
base-modules() {
  $PY27/python -S ./base_modules.py 
}

"$@"
