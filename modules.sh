#!/bin/bash
#
# Usage:
#   ./modules.sh <function name>

set -o nounset
set -o pipefail
set -o errexit

source common.sh

list() {
  pushd $PY27
  echo Lib/*.py
  echo Modules/*.c
  popd
}

list2() {
  pushd $PY27
  ../module_manifest.py
  popd
}


"$@"
