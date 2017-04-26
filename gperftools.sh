#!/bin/bash
#
# Usage:
#   ./profile.sh <function name>

set -o nounset
set -o pipefail
set -o errexit

download() {
  wget --directory _tmp \
    'https://github.com/gperftools/gperftools/releases/download/gperftools-2.5/gperftools-2.5.tar.gz'
}

# note: Ubuntu has a lot of packages: libgoogle-perftoolsdev, perftools4,
# libtcmalloc-minimal4, google-perftools.
# I think it's more portable across distros so just use the source tarball?

# Woah this Perl script is 5600 lines!  It has a bunch of unit tests at the
# end.
#
# uses: warnings, Getopt::Long, Cwd, POSIX
# tools: objdump, nm, addr2line, c++filt
# also: dot, gv, evince, kcachegrind, etc.

count() {
  wc -l $PERFTOOLS/src/pprof 
  less $PERFTOOLS/src/pprof 
}


# See slice.sh for the build variants


# https://gperftools.github.io/gperftools/cpuprofile.html

readonly PERFTOOLS=_tmp/gperftools-2.5

# build perftols itself
build() {
  pushd $PERFTOOLS
  #time ./configure
  time make -j 7
  popd
}

pprof() {
  $PERFTOOLS/src/pprof "$@"
}

# Heap profiler:
#
# https://gperftools.github.io/gperftools/heapprofile.html

"$@"
