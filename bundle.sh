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

readonly APP_ZIP=~/git/oil/benchmarks/_tmp/app.zip 

build() {
  local bin=${1:-$PY27/python}
  local out=${2:-$PY27/app.bundle}

  mkdir -p _bin
  #local out=_bin/app.bundle
  cat $bin $APP_ZIP > $out
  chmod +x $out

  ls -l $out
}

build-ovm() {
  build $PY27/ovm2 $PY27/ovm2.bundle
}

# Use it as an executable and as a zip file.
run() {
  time $PY27/app.bundle -S $PY27/app.bundle
}

# This is what I want to work.  It can't find 'runpy', which is in the Lib
# folder.  That is for the '-m' flag.  I have to bundle that in to the app.
# OK I have to set the path for sys.path.
run-separate() {
  time _bin/app.bundle -S _bin/app.bundle
}

# Oops, this expects a .pyc file!  Yeah I need to restore the app bundle
# behavior.
run-ovm() {
  time $PY27/ovm2.bundle $PY27/ovm2.bundle
}

run-fast() {
  $PY27/python -S $APP_ZIP
}



"$@"
