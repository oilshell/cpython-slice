#!/bin/bash
#
# Build actions used in the Makefile.
#
# Usage:
#   ./actions.sh <function name>

set -o nounset
set -o pipefail
set -o errexit

source common.sh

module-manifest() {
  pushd $PY27
  ../module_manifest.py
  popd
}


"$@"
