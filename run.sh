#!/bin/bash
#
# Usage:
#   ./run.sh <function name>

set -o nounset
set -o pipefail
set -o errexit

source common.sh

readonly PY27=Python-2.7.13

build() {
  cd $PY27
  #time ./configure 
  time make -j 7 || true
}

copy-bin() {
  local suffix=${1:-}
  mkdir -p _bin
  cp $PY27/python _bin/python${suffix}.unstripped
  strip -o _bin/python${suffix}.stripped _bin/python${suffix}.unstripped
}

# It's indeed a little smaller without threads, and it doesn't dynamically link
# against pthreads.  TODO: How to use Modules/Setup?
build-small() {
  cd $PY27
  make clean
  time ./configure --without-threads
  time make -j 7 || true
}

# 2.0 MB stripped, 8.1 MB unstripped
stats() {
  mkdir -p _tmp

  ls -l -h _bin/python*

  # Not dynamically linked to much.  libutil, libm, libpthread.
  # I guess I want to get rid of the threads.
  ldd _bin/python*

  nm _bin/python.unstripped > _tmp/symbols.txt
  head _tmp/symbols.txt
  wc -l _tmp/symbols.txt
}

# TODO: How to list global variables?


# configure --help
# CC
# --with-valgrind
# --with-signal-module

# --without-PACKAGE=
# --with-PACKAGE=

readonly MOD=$PY27/build/lib.linux-x86_64-2.7

copy-modules() {
  mkdir -p _mod _mod-stripped

  cp $MOD/*.so _mod

  for m in _mod/*.so; do
    strip -o _mod-stripped/$(basename $m) $m
  done
}

mod-stats() {
  du --si -s _mod
  du --si -s _mod-stripped

  # unicodedata is biggest, codecs, pyexpat.
  # _io is pretty big too.
  # _datetime.  wonder why that is big.
  find _mod-stripped -name '*.so' -a -printf '%s %P\n' | sort -n
}

"$@"
