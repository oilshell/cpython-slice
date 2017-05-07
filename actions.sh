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

_py-deps() {
  # I need the right relative path for Oil
  ln -s -f $PWD/py_deps.py ~/git/oil/_tmp
  $PY27/python -S ~/git/oil/_tmp/py_deps.py "$@"
}

oil-deps() {
  #PYTHONPATH=~/git/oil ~/git/oil/_tmp/py_deps.py bin.oil

  # This version gets the paths out of the repo.  But it requires that we
  # build all of Python!
  #
  # OK yeah so there are a few steps to building minimal app bundles.
  # 1. Build all of Python normally.  Normal -D options.
  #    ./run.sh build-clang-default
  # 2. Then run a special build that is based on that.
  #
  # Only need a debug build.

  # Run  grep -F .so  for the native dependencies.  Have to add those
  # somewhere.
  PYTHONPATH=~/git/oil _py-deps bin.oil "$@"
}

hello-deps() {
  PYTHONPATH=testdata _py-deps hello "$@"
}

# To test building stdlib.
clean-pyc() {
  find $PY27/Lib -name '*.pyc' | xargs --no-run-if-empty -- rm --verbose
}

"$@"
