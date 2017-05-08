#!/bin/bash
#
# Usage:
#   ./count.sh <function name>

set -o nounset
set -o pipefail
set -o errexit

source common.sh

python-build-scripts() {
  pushd $PY27

  # 1849 lines of input
  echo DATA
  wc -l Modules/Setup.dist Modules/config.c.in pyconfig.h.in
  echo

  # 9K lines of code!
  echo SOURCE CODE
  wc -l setup.py Makefile.pre.in configure.ac Modules/makesetup #Doc/Makefile
  echo

  echo MODULES
  { echo Modules/zlib/Makefile.in
    find Modules/_ctypes -name 'Makefile.am'
  } | xargs wc -l
  echo

  # 19K lines of output!
  echo GENERATED
  wc -l Makefile configure Modules/config.c pyconfig.h
  echo

  echo WINDOWS
  wc -l PCbuild/*.bat #PCbuild/*.vcxproj*
  echo

  echo MAC
  find Mac/ -name '*Makefile*' | xargs wc -l
  echo

  popd
}

# NOTE: Almost all of this is Modules/ and Lib/.  Batteries included.
python-source() {
  echo 'Number of Python source files'
  git ls-files $PY27 | wc -l
  echo

  echo 'Number of core Python source files'
  git ls-files $PY27/{Python,Include,Objects,Parser,Grammar} | wc -l
  echo
}

# 144K shipped for hello.tar.  Will be more for OVM.
tar-lines() {
  find _tmp/tar-test -name '*.[ch]' | xargs wc -l | sort -n
}

"$@"
