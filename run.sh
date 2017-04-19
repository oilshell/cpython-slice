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

build-default() {
  cd $PY27
  make clean
  time ./configure
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

# Uh this is almost certainly out of date.  Got rid of it.
##if LONG_BIT != 8 * SIZEOF_LONG
#/* 04-Oct-2000 LONG_BIT is apparently (mis)defined as 64 on some recent
# * 32-bit platforms using gcc.  We try to catch that here at compile-time
# * rather than waiting for integer multiplication to trigger bogus
# * overflows.
# */
##error "LONG_BIT definition appears wrong for platform (bad gcc/glibc config?)."
##endif

# OK now we get a link error.  pgenmain doesn't link?
# pgenmain doesn't respect cflags?
# /usr/bin/ld: i386 architecture of input file `Parser/pgenmain.o' is incompatible with i386:x86-64 output
#
# This is a reason to remove pgen from the build!

build-m32() {
  cd $PY27
  make clean
  time ./configure --without-threads
  time make -j 7 CFLAGS=-m32 libpython2.7.a || true
}

install-lcov() {
  sudo apt-get install lcov
}

# I think this is the GCC one.  'make coverage' reinvokes make, so it builds
# all modules too.
# 3.1 M binary instead of 2.0.
build-coverage() {
  cd $PY27
  make clean
  time ./configure --without-threads
  time make -j 7 coverage || true
}

lcov-report() {
  cd $PY27
  time make coverage-lcov
}

# lcov: this is a reporting tool!  Need to install it.

# -S to ignore site.py.
# sys is builtin

# What are the .gcda and .gcno?
# https://gcc.gnu.org/onlinedocs/gcc/Gcov-Data-Files.html
# .gcda: -ftest-coverage
# .gcno: -fpropfile-arcs
# There is also the -fprofiledir option.

run-cov() {
  PYTHONHOME=$PY27 _bin/python-cov.stripped -S "$@"
}

find-cov() {
  find $PY27 '(' -name '*.gcda' -o -name '*.gcno' ')' "$@"
}

list-cov() {
  find-cov -a -printf '%s %P\n'

  #find $PY27 '(' -name '*.gcov' ')' -a -printf '%s %P\n'
    #xargs --no-run-if-empty -- ls -l
    #xargs --no-run-if-empty -- rm --verbose
}

rm-cov() {
  find-cov | xargs --no-run-if-empty -- rm --verbose
}

# This gcc tool gives you text.
# NOTE: copied from 
gcov-report() {
  mkdir -p _gcov
  rm --verbose -f _gcov/*

  # After running tests with bwk-cov, .gcno and .gcda files are in
  # obj/bwk-cov, next to the objects.

  # This fails
  #gcov --object-directory $PY27/Python $PY27/Python/*.c
  #mv --verbose *.gcov _gcov

  gcov --object-directory $PY27/Python $PY27/Python/pythonrun.c
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
