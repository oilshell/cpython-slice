#!/bin/bash
#
# Bundle Python interpreter with an app.
#
# Usage:
#   ./bundle.sh <function name>

set -o nounset
set -o pipefail
set -o errexit

source common.sh

# Layout:
#
# ELF file
# zip file
#
# Then you can just pass $0

build() {
  mkdir -p _bin
  #local out=_bin/app.bundle
  local out=$PY27/app.bundle
  cat $PY27/python.stripped ~/git/oil/benchmarks/_tmp/app.zip > $out
  chmod +x $out

  ls -l $out
}

# Use it as an executable and as a zip file.
run() {
  #_bin/app.bundle -S _bin/app.bundle
  time $PY27/app.bundle -S $PY27/app.bundle
}

"$@"
