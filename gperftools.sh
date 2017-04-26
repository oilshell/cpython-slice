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
