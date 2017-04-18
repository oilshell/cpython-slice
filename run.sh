#!/bin/bash
#
# Usage:
#   ./run.sh <function name>

set -o nounset
set -o pipefail
set -o errexit

readonly PY27=Python-2.7.13

build() {
  cd $PY27
  #time ./configure 
  time make -j 7 || true
}

copy-strip() {
  mkdir -p _bin
  cp $PY27/python _bin/python.unstripped
  strip -o _bin/python.stripped _bin/python.unstripped
}

# 2.0 MB stripped, 8.1 MB unstripped
stats() {
  mkdir -p _tmp

  ls -l -h _bin/python.*

  # Not dynamically linked to much.  libutil, libm, libpthread.
  # I guess I want to get rid of the threads.
  ldd _bin/python.*

  nm _bin/python.unstripped > _tmp/symbols.txt
  head _tmp/symbols.txt
  wc -l _tmp/symbols.txt
}

# TODO: How to list global variables?

"$@"
