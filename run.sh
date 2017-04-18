#!/bin/bash
#
# Usage:
#   ./run.sh <function name>

set -o nounset
set -o pipefail
set -o errexit

readonly PY27=Python-2.7.13

build() {
  cd $PY27
  #time ./configure 
  time make -j 7 || true
}

"$@"
