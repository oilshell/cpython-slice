#!/bin/bash
#
# Usage:
#   ./slice.sh <function name>

set -o nounset
set -o pipefail
set -o errexit

source common.sh

readonly OVM_PARSER_OBJS='Parser/myreadline.c'

readonly OVM_PYTHON_OBJS='
		Python/_warnings.c
		Python/bltinmodule.c
		Python/ceval.c
		Python/codecs.c
		Python/errors.c
		Python/frozen.c
		Python/frozenmain.c
		Python/future.c
		Python/getargs.c
		Python/getcompiler.c
		Python/getcopyright.c
		Python/getplatform.c
		Python/getversion.c
		Python/import.c
		Python/importdl.c
		Python/marshal.c
		Python/modsupport.c
		Python/mystrtoul.c
		Python/mysnprintf.c
		Python/pyarena.c
		Python/pyctype.c
		Python/pyfpe.c
		Python/pymath.c
		Python/pystate.c
		Python/pythonrun.c
    Python/random.c
		Python/structmember.c
		Python/sysmodule.c
		Python/traceback.c
		Python/getopt.c
		Python/pystrcmp.c
		Python/pystrtod.c
		Python/dtoa.c
		Python/formatter_unicode.c
		Python/formatter_string.c
		Python/dynload_shlib.c
'

OBJECT_OBJS='
		Objects/abstract.c
		Objects/boolobject.c
		Objects/bufferobject.c
		Objects/bytes_methods.c
		Objects/bytearrayobject.c
		Objects/capsule.c
		Objects/cellobject.c
		Objects/classobject.c
		Objects/cobject.c
		Objects/codeobject.c
		Objects/complexobject.c
		Objects/descrobject.c
		Objects/enumobject.c
		Objects/exceptions.c
		Objects/genobject.c
		Objects/fileobject.c
		Objects/floatobject.c
		Objects/frameobject.c
		Objects/funcobject.c
		Objects/intobject.c
		Objects/iterobject.c
		Objects/listobject.c
		Objects/longobject.c
		Objects/dictobject.c
		Objects/memoryobject.c
		Objects/methodobject.c
		Objects/moduleobject.c
		Objects/object.c
		Objects/obmalloc.c
		Objects/rangeobject.c
		Objects/setobject.c
		Objects/sliceobject.c
		Objects/stringobject.c
		Objects/structseq.c
		Objects/tupleobject.c
		Objects/typeobject.c
		Objects/weakrefobject.c

    Objects/unicodeobject.c
    Objects/unicodectype.c
'

# Non-standard lib stuff.
MODULE_OBJS='
		Modules/getpath.c
		Modules/main.c
		Modules/gcmodule.c
'

# The stuff in Modules/Setup.dist, plus zlibmodule.c and signalmodule.c.
# NOTE: In Pyhon, signalmodule.c is specified in Modules/Setup.config, which
# comes from 'configure' output.
MODOBJS='
Modules/posixmodule.c
Modules/errnomodule.c  
Modules/pwdmodule.c
Modules/_sre.c  
Modules/_codecsmodule.c  
Modules/_weakref.c
Modules/zipimport.c  
Modules/zlibmodule.c
Modules/signalmodule.c
'

OVM_LIBRARY_OBJS="
		Modules/getbuildinfo.c
		$OVM_PARSER_OBJS
		$OBJECT_OBJS
		$OVM_PYTHON_OBJS 
		$MODULE_OBJS
		$MODOBJS
"

# Install prefix for architecture-independent files
readonly prefix='"/usr/local"'  # must be quoted string

# Install prefix for architecture-dependent files
readonly exec_prefix="$prefix"
readonly VERSION='"2.7"'
readonly VPATH='""'
readonly pythonpath='""'

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
build() {
  local out=${1:-$PY27/ovm2}
  local module_init=${2:-$PY27/Modules/config.c}
  local main_name=${3:-_tmp/hello/main_name.c}
  shift 3

  local abs_out=$PWD/$out
  local abs_module_init=$PWD/$module_init
  local abs_main_name=$PWD/$main_name

  # $(cat $PWD/stdlib_modules.txt)
  local c_module_paths=''

  #echo $OVM_LIBRARY_OBJS
  pushd $PY27
  # Slower when done serially.

  # PREFIX, EXEC_PREFIX, VERSION, VPATH, etc. are from Modules/getpath.o

  # Not using this for now because of libc.so
    #-D OIL_DISABLE_DLOPEN \

  # So the OVM is ~600K smaller now.  1.97 MB for ./run.sh build-default.  1.65
  # MB for ./run.sh build-clang-small.

  CC=$CLANG
  #CC=gcc

  CFLAGS=
  #CFLAGS=-m32

  time $CC \
    -g \
    $CFLAGS \
    -D OIL_MAIN \
		-D PYTHONPATH="$pythonpath" \
		-D PREFIX="$prefix" \
		-D EXEC_PREFIX="$exec_prefix" \
		-D VERSION="$VERSION" \
		-D VPATH="$VPATH" \
    -D Py_BUILD_CORE \
    -I . -I Include \
    -o $abs_out \
    $OVM_LIBRARY_OBJS \
    $abs_module_init \
    $abs_main_name \
    $c_module_paths \
    Modules/ovm.c \
    -l dl -l util -l m -l z \
    "$@" \
    || true
  popd
}

# build the optimized one.  Makefile uses -O3.

# Clang -O2 is 1.37 MB.  18 seconds to compile.
#   -m32 is 1.12 MB.  But I probably have to redefine a few things because
#   there are more warnings.
# -O3 is 1.40 MB.

# GCC -O2 is 1.35 MB.  21 seconds to compile.

build-dbg() {
  local out=$1
  build $out '' -O0
}

build-opt() {
  local out=$1
  build $out '' -O3
}

debug-ovm2() {
  gdb --tui --args $PY27/ovm2 "$@"
}

test-ovm2() {
  echo ---
  echo 'Running nothing'
  echo ---

  _OVM_RUN_SELF=0 $PY27/ovm2 || true

  echo ---
  echo 'Running lib.pyc'
  echo ---

  _OVM_RUN_SELF=0 $PY27/ovm2 testdata/lib.pyc

  echo ---
  echo 'Running hello.zip'
  echo ---

  _OVM_RUN_SELF=0 $PY27/ovm2 _tmp/hello.zip

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

# 123K lines.
# Excluding MODOBJS, it's 104K lines.
#
# Biggest: posixmodule,unicodeobject,typeobject,ceval.
#
# Remove tmpnam from posixmodule, other cruft.
#
# Big ones to rid of: unicodeobject.c, import.c
# codecs and codecsmodule?  There is some non-unicode stuff there though.
#
# Probably need unicode for compatibility with modules and web frameworks
# especially.

count-lines() {
  pushd $PY27
  wc -l $OVM_LIBRARY_OBJS Include/*.h | sort -n

  # 90 files.
  # NOTE: This doesn't count headers.
  echo
  echo 'Files:'
  { for i in $OVM_LIBRARY_OBJS Include/*.h; do
     echo $i
    done 
  } | wc -l

  popd
}

test-hello() {
  ./run.sh test-hello $PY27/ovm2
}

symbols() {
  local bin=$1
  local out=$2
  nm $bin | cut -d ' ' -f 3 | sort > $out
}

compare-symbols() {
  pushd $PY27
  ls -l python ovm2

  symbols python python-sym.txt
  symbols ovm2 ovm2-sym.txt

  wc -l *-sym.txt

  diff -u python-sym.txt ovm2-sym.txt
  popd
}

bloaty() {
  local bin=~/git/other/bloaty/bloaty
  
  test -f $bin && $bin "$@"
}

compare-size() {
  pushd $PY27
  strip -o python.stripped python
  strip -o ovm2.stripped ovm2

  echo python.stripped
  bloaty python.stripped 
  echo
  echo ovm2.stripped
  bloaty ovm2.stripped

  # Supports diffs.  The one after -- is the base.
  echo
  echo SECTIONS diff
  bloaty ovm2.stripped -- python.stripped

  # _PyUnicodeUCS2_ToNumeric is 17.7 Ki bigger.  And then there are 560K of
  # [Other]?  Is that due to the compiler or what?
  echo
  echo SYMBOLS diff
  bloaty -d symbols ovm2 -- python
  echo

  ls -l python.stripped ovm2.stripped

  popd
}

# 604 Ki of .text and 122 Ki of .rodata.

# ovm2 is 786 Ki of .text, 223 Ki o .rotdata, and 197 Ki of .data.
# We're in spitting distance.  Is it unicode data?

bash-size() {
  bloaty /bin/bash
  echo
  ls -l /bin/bash
}

# ZSH is smaller, only 495 KiB .textand 41 KiB .rodata.  692 KB data size.
zsh-size() {
  bloaty /usr/bin/zsh
  echo
  ls -l $(readlink -f /usr/bin/zsh)
}

"$@"
