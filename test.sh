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

"$@"
