#!/bin/bash
#
# Usage:
#   ./cov.sh <function name>

set -o nounset
set -o pipefail
set -o errexit

source common.sh

# Coverage Usage:
#
# build-coverage (gcc version, not Clang)
# run-cov-hello
# install-lcov
# lcov-report (HTML, 3-4 seconds)
# gcov-report
# rm-gcda -- to run another one

# HTML reporter
install-lcov() {
  sudo apt-get install lcov
}

# Matches Makefile.
# Need to get these into setup.py invocation.
readonly GCC_COV_FLAGS='-O0 -pg -fprofile-arcs -ftest-coverage'

# I think this is the GCC one.  'make coverage' reinvokes make, so it builds
# all modules too.
# 3.1 M binary instead of 2.0.
build-coverage() {
  cd $PY27
  make clean
  time ./configure --without-threads
  # extra cflags for building .o files for Modules/
  # CFLAGS only makes it through to the -shared invocation.
  export OIL_MODULE_CFLAGS="$GCC_COV_FLAGS"
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
  #PYTHONHOME=$PY27 _bin/python-cov.stripped -S "$@"
  #PYTHONHOME=$PY27 _bin/python-cov.unstripped -S "$@"

  # Have to run this directly, in the right working directory, to generate the
  # .gcda files.
  pushd $PY27
  ./python -S "$@"
  popd
}

run-osh() {
  run-cov ~/git/oil/bin/oil.py osh -c 'echo "hi"; ls /'
}

# dict lookup
run-cov-dict() {
  run-cov -c 'd = {True: "hi"}; print d[True]'
}

run-cov-n() {
  local count=$1
  run-cov - $count <<EOF
import sys
n = int(sys.argv[1])
d = {}
for i in xrange(n):
  unused = d.get(str(i))
EOF
}

run-cov-slots() {
  run-cov <<EOF
class Point(object):
  __slots__ = ("x", "y")
print Point
EOF
}

# OH .gcno geneated at COMPILE TIME
find-cov() {
  find $PY27 '(' -name '*.gcda' -o -name '*.gcno' -o -name '*.gcov' ')' "$@"
}

list-cov() {
  find-cov -a -printf '%s %P\n'

  #find $PY27 '(' -name '*.gcov' ')' -a -printf '%s %P\n'
    #xargs --no-run-if-empty -- ls -l
    #xargs --no-run-if-empty -- rm --verbose
}

# These are generated at runtime
rm-gcda() {
  find $PY27 -name '*.gcda' | xargs --no-run-if-empty -- rm --verbose
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

  pushd $PY27
  # creates Python#pythonrun.c.gcov.  Dumb!
  gcov --preserve-paths "$@"
  find . -name '*.gcov'
  popd
  #gcov \
  #  --source-prefix $PY27/Python \
  #  --object-directory $PY27/Python $PY27/Python/pythonrun.c
}

gcov1() {
  gcov-report Python/pythonrun.c
}

gcov2() {
  gcov-report Objects/typeobject.c Objects/dictobject.c
}

show-dict-counts() {
  # Get the exact lines
  grep -E '320:lookdict|408:lookdict_string' "$PY27/Objects#dictobject.c.gcov"
}

one-dict-count() {
  local out=$1
  shift

  rm-gcda > /dev/null

  # Cumulative job
  "$@"

  gcov2
  show-dict-counts > $out
}

# TODO: Iterate over n and Class in demo.py.
# Put them in output files
#
# I guess I should make a Berstein chaining function?

# TODO: Plot ratio of n to dictobject lookups.

one-hello() {
  local out=_gcov/out.txt
  for n in 10 1000 10000; do
    echo
    echo "--- $n ---"
    echo
    one-dict-count $out run-cov-n $n
    cat $out
  done
}

"$@"
