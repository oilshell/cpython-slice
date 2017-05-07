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
  cd $PY27
  ../module_manifest.py
}

# Modules needed to 'import runpy'.
runpy-modules() {
  $PY27/python -S ./default_modules.py "$@"
}

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
_py-deps() {
  # I need the right relative path for Oil
  ln -s -f $PWD/py_deps.py ~/git/oil/_tmp
  $PY27/python -S ~/git/oil/_tmp/py_deps.py "$@"
}

oil-deps() {
  PYTHONPATH=~/git/oil _py-deps bin.oil "$@"
}

hello-deps() {
  PYTHONPATH=testdata _py-deps hello "$@"
}

make-deps() {
  local discovered=${1:-_tmp/hello/discovered-c.txt}

  # TODO: For each module, look it up in the manifest.
  # I guess make a Python file.

  echo "# TODO $discovered"
  #cat $discovered
  echo "# --"
}

#
# C Code generation.  The three functions below are adapted from
# Modules/makesetup.
#

extdecls() {
	for mod in "$@"; do
		echo "extern void init$mod(void);"
  done
}
		
initbits() {
	for mod in "$@"; do
    echo "    {\"$mod\", init$mod},"
	done
}

# Ported from sed to awk.  Awk is MUCH nicer (no $NL ugliness, -v flag, etc.)
gen-module-init() {
  local extdecls=$(extdecls "$@")
  local initbits=$(initbits "$@")

  local template=$PY27/Modules/config.c.in 

	awk -v template=$template -v extdecls="$extdecls" -v initbits="$initbits" '
		BEGIN {
      print "/* Generated automatically from $template by makesetup. */"
    }
		/MARKER 1/ {
      print extdecls
      next
    }
		/MARKER 2/ {
      print initbits
      next
    }
    {
      print $0
    }
		' $template
}

#
# C Modules
#

join-modules() {
  local static=${1:-static-c-modules.txt}
  local discovered=${2:-_tmp/oil/discovered-c.txt}

  # Filter out comments, print the first line.
  #
  # TODO: I don't want to depend on egrep and GNU flags on the target sytems?
  # Ship this file I guess.
  egrep --no-filename --only-matching '^[a-zA-Z_]+' $static $discovered \
    | sort | uniq
}

#
# Misc
#

# To test building stdlib.
clean-pyc() {
  find $PY27/Lib -name '*.pyc' | xargs --no-run-if-empty -- rm --verbose
}

"$@"
