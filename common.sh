#!/bin/bash

set -o nounset
set -o pipefail
set -o errexit

bin-stats() {
  local bin=$1
  echo "--- $bin ---"
  ls -l -h $bin
  echo
  file $bin
  echo
  ldd $bin
  echo
  nm $bin | wc -l
  echo
}
