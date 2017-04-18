#!/bin/bash
#
# Usage:
#   ./run.sh <function name>

set -o nounset
set -o pipefail
set -o errexit

source common.sh

readonly PY27=Python-2.7.13


# 'make libpython2.7.a' to avoid building external modules.  Assuming we don't
# need these now.
# This only takes 9 seconds, vs. 42 seconds for the full build.
build-libpython() {
  cd $PY27
  make clean
  # This only takes 9 seconds.  Compiling modules takes longer.
  time make -j 7 libpython2.7.a || true

  # has:
  # signalmodule, posixmodule,
  # {errno,pwd,_sre,_codecs,_weakrefzipimport,symtable,xxsubtype}module
}

build() {
  cd $PY27
  make clean
  #time ./configure 
  time make -j 7 || true
}

# It's indeed a little smaller without threads, and it doesn't dynamically link
# against pthreads.  TODO: How to use Modules/Setup?

# ./configure generates and EXECUTABLE shell script config.status!

# That changes Modules/Setup.config.in -> Modules/Setup.config.  Now the lin
# Now it has this line COMMENTED OUT:
#thread threadmodule.c

build-small() {
  cd $PY27
  make clean
  time ./configure --without-threads
  time make -j 7 || true
}

# Oops, this doesn't work!
# Include/pyport.h:895:2: error: #error "LONG_BIT definition appears wrong for
# platform (bad gcc/glibc config?)."
build-m32() {
  cd $PY27
  make clean
  time ./configure --without-threads
  time make -j 7 CFLAGS=-m32 python || true
}

copy-bin() {
  local suffix=${1:-}
  mkdir -p _bin
  cp $PY27/python _bin/python${suffix}.unstripped
  strip -o _bin/python${suffix}.stripped _bin/python${suffix}.unstripped
}

# lib is basically the same size as the Python executable.
copy-lib() {
  local label=${1:-}
  mkdir -p _lib
  local unstripped=_lib/libpython2.7.a.unstripped
  cp $PY27/libpython2.7.a $unstripped
  strip -o ${unstripped/unstripped/stripped} $unstripped 
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
