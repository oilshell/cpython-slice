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
		Python/graminit.c
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

# NOTE: config.c is generated?  I think that is fine.  ./configure
# --without-threads and then build the slice.
MODULE_OBJS='
		Modules/config.c
		Modules/getpath.c
		Modules/main.c
		Modules/gcmodule.c
'

# TODO: _struct and array also useful.
# From Modules/Setup
MODOBJS='
Modules/signalmodule.c
Modules/posixmodule.c
Modules/errnomodule.c  
Modules/pwdmodule.c
Modules/_sre.c  
Modules/_codecsmodule.c  
Modules/_weakref.c
Modules/zipimport.c  
Modules/fcntlmodule.c 
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
readonly PYTHONPATH='""'

mod-setup() {
  pushd $PY27
	Modules/makesetup \
    -c Modules/config.c.in \
		-s Modules \
		Modules/Setup.config \
		Modules/Setup.local \
		Modules/Setup
  popd
}

build() {
  echo $OVM_LIBRARY_OBJS
  pushd $PY27
  # Slower when done serially.

  # PREFIX, EXEC_PREFIX, VERSION, VPATH, etc. are from Modules/getpath.o

  time $CLANG -g \
    -DOIL_DISABLE_DLOPEN -DOIL_MAIN \
		-DPYTHONPATH="$PYTHONPATH" \
		-DPREFIX="$prefix" \
		-DEXEC_PREFIX="$exec_prefix" \
		-DVERSION="$VERSION" \
		-DVPATH="$VPATH" \
    -I. -IInclude -DPy_BUILD_CORE \
    -o ovm2 \
    $OVM_LIBRARY_OBJS \
    Modules/ovm.c \
    -ldl -lutil -lm \
    || true
  popd
}

"$@"
