#!/bin/bash
#
# Usage:
#   ./run.sh <function name>

set -o nounset
set -o pipefail
set -o errexit

source common.sh

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

# we're always doing it without threads for now.  not sure about signal module
# just yet.  have to implement "trap"?
config() {
  cd $PY27
  time ./configure --without-threads

  #cp -v ../modulessetup modules/setup
}

build-default() {
  cd $PY27
  make clean
  time make -j 7 || true
}

# Build modules statically because we want to disable dlopen?  What about
# libc.so?
#
# We want the fcntl module for sure.
#
# NOTE: after putting _json line in, you get init_json in the 'nm' output of
# _bin/python-with-json.unstripped.
#
build-static-modules() {
  cd $PY27
  make clean
  time make -j 7 || true
}

# It's indeed a little smaller without threads, and it doesn't dynamically link
# against pthreads.

# ./configure generates and EXECUTABLE shell script config.status!

# That changes Modules/Setup.config.in -> Modules/Setup.config.  Now the lin
# Now it has this line COMMENTED OUT:
#thread threadmodule.c

build-small() {
  cd $PY27
  make clean
  export OIL_MAX_EXTENSIONS=5
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
  time make -j 7 CFLAGS=-m32 libpython2.7.a || true
}

# hm the Makefile defines CC and CXX as {gcc,g++} -pthread
# 
# Woah clang is faster and smaller.
# I think it's 6-8 seconds vs. 12.5 seconds to compile vs. gcc-small.
# And binary is 1.6 MB vs 1.9 MB!  Wow.
#
# (Clang 4.0 seems to be slower than Clang 3.4 from Ubuntu.)

build-clang-small() {
  cd $PY27
  make clean
  export OIL_MAX_EXTENSIONS=5
  time make -j 7 CC=$CLANG
}

# 3.5 seconds for -O0.  ~8.5 seconds for default (I think -O2).

# Makefile.pre.in does this.  If we have all modules static eventually, then we
# don't need this part.  What is sys.path?  The only thing we care about is
# stdlib modules?
#
# ovm has the standard library; oil is the oil repo?
# OVMPATH=/usr/lib/ovm/:/usr/lib/oil/
# /usr/bin/ovm -- with symlinks pointing to it.
#
# "Create build directory and generate the sysconfig build-time data there.
# pybuilddir.txt contains the name of the build dir and is used for sys.path
# fixup -- see Modules/getpath.c."

build-clang-fast() {
  cd $PY27
  make clean
  export OIL_MAX_EXTENSIONS=5
  # NOTE: The build process uses the -m path.  So we would have to change that.
  # ./python -E -S -m sysconfig --generate-posix-vars 

  time make -j 7 CC=$CLANG CFLAGS='-O0 -DOIL_DISABLE_DLOPEN' || true
}

# Oh but with coverage it's faster.  Only 4 seconds!  I think this is because
# coverage builds are unoptimized.
# 5.3 MB instead of 1.6 MB.
#
# NOTE: LDFLAGS must be set as well to output .profraw.
build-clang-coverage() {
  cd $PY27
  make clean
  time make -j 7 CC=$CLANG CFLAGS="$CLANG_COV_FLAGS" LDFLAGS="$CLANG_COV_FLAGS" || true
}

# NOTE: 'import site' tries to find _sysconfigdata?  We behave like -S.
#
# TODO: ovm should run .pyc files as embedded data?  Linker data or generate C
# source code and compile it?

# Why is this bigger?  It's somehow not stripping unused symbols?
build-ovm() {
  cd $PY27
  make clean
  export OIL_MAX_EXTENSIONS=0
  # NOTE: The build process uses the -m path.  So we would have to change that.
  # ./python -E -S -m sysconfig --generate-posix-vars 

  cflags='-DOIL_DISABLE_DLOPEN -DOIL_MAIN' 
  #cflags='-O0 -DOIL_DISABLE_DLOPEN -DOIL_MAIN' 
  # debug info
  cflags='-g -DOIL_DISABLE_DLOPEN -DOIL_MAIN' 
  time make -j 7 CC=$CLANG CFLAGS="$cflags" ovm

  ls -l ovm
}

build-hello() {
  pushd testdata
  rm -v -f hello.pyc lib.pyc
  python -c 'import hello, lib'

  find . -name '*.pyc'

  # Hm OVM needs -c so you can print sys.path and stuff.  Oh but then it would
  # need a parser!  Doh.

  # Under OVM, sys.path doesn't have '', which is the current directory.

  # Some how it gets /usr/lib/python2.7.zip.
  # I think you should make and ovm27.zip ?
  popd
}

readonly RUNPY_DEPS=($PY27/Lib/{runpy,pkgutil,os,posixpath,stat,genericpath,warnings,linecache,types,UserDict,_abcoll,abc,_weakrefset,copy_reg}.pyc)

build-hello-zip() {
  local out=${1:-_tmp/hello.zip}

  build-hello

  mkdir -p _tmp/app
  cp testdata/hello.pyc _tmp/app/__main__.pyc
  cp testdata/lib.pyc _tmp/app/

  # there are a bunch of startup dependencies!  Mainly because of using the
  # runpy module and the whole importer / get_loader() mechanism.  Maybe I
  # should replace runpy?

  # Wow this is a lot.  Why UserDict?
  # This is just for runpy?
  cp -v "${RUNPY_DEPS[@]}" _tmp/app/

  # Compile it
  #$PY27/python -S -c 'import zipfile, collections'

  # For zipfile access
  #cp -v \
  #  $PY27/Lib/{zipfile,collections,struct}.pyc \
  #  _tmp/app/

  rm -f $out
  local abs_out=$PWD/$out

  pushd _tmp/app
  zip -r $abs_out .
  popd

  ls -l $out
  unzip -l $out
}

update-oil-zip() {
  local tmp=_tmp/update-oil-zip
  mkdir -p $tmp
  cp -v "${RUNPY_DEPS[@]}" $tmp

  # Missing C modules: operator.  From cgi.

  $PY27/python -c 'import cgi'

  # NOTE: cgi is in asdl, not really needed?  Well it's only needed for tools.
  cp -v $PY27/Lib/{__future__,optparse,textwrap,string,re,sre_compile,sre_parse,sre_constants,traceback,cgi}.pyc \
    $tmp

  pushd $tmp
  set -x
  zip ~/git/oil/opy/_tmp/oil.zip *.pyc
  popd
}

test-hello() {
  local bin=${1:-$PY27/ovm}

  build-hello

  # add current dir
  export PYTHONPATH=testdata
  time $bin testdata/hello.pyc

  #time strace $bin testdata/hello.pyc

  #gdb --tui --args $bin testdata/hello.pyc
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

diff-orig() {
  git diff f36f034614583c1487f1431ab3ad02db603e3a10.. $PY27/Python

  git diff f36f034614583c1487f1431ab3ad02db603e3a10.. $PY27/Modules

  # one diff for __ change
  git diff f36f034614583c1487f1431ab3ad02db603e3a10.. $PY27/Objects
}

count-patches() {
  find $PY27 -name '*.c' | xargs grep OVM_MAIN
}

files-changed() {
  find $PY27 -name '*.c' | xargs grep -l OVM_MAIN
}

# Also Include/pythonrun.h, Modules/config.c.in
copy() {
  for f in $(files-changed); do
    cp -v $f ~/git/oil/$f
  done
}

"$@"
