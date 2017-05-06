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

# This has Python paths, but no C paths!
default-modules() {
  $PY27/python -S ./default_modules.py "$@"
}

# To test building stdlib.
clean-pyc() {
  find $PY27/Lib -name '*.pyc' | xargs --no-run-if-empty -- rm --verbose
}

"$@"
