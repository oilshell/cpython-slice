#!/bin/bash
#
# Usage:
#   ./test.sh <function name>

set -o nounset
set -o pipefail
set -o errexit

make-zip() {
  local out=_tmp/make-zip-test.zip 
  ./make_zip.py $out _tmp/py.default-modules.txt
  unzip -l $out
}

oil-bundle() {
  _bin/oil.bundle osh -c 'echo hi'
  ln -s oil.bundle _bin/osh
  _bin/osh -c 'echo hi from osh'
}

"$@"
