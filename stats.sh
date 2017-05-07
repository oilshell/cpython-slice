#!/bin/bash
#
# Usage:
#   ./stats.sh <function name>

set -o nounset
set -o pipefail
set -o errexit

source common.sh

symbols() {
  local bin=$1
  local out=$2
  nm $bin | cut -d ' ' -f 3 | sort > $out
}

compare-symbols() {
  pushd $PY27
  ls -l python ovm2

  symbols python python-sym.txt
  symbols ovm2 ovm2-sym.txt

  wc -l *-sym.txt

  diff -u python-sym.txt ovm2-sym.txt
  popd
}

bloaty() {
  local bin=~/git/other/bloaty/bloaty
  
  test -f $bin && $bin "$@"
}

compare-size() {
  pushd $PY27
  strip -o python.stripped python
  strip -o ovm2.stripped ovm2

  echo python.stripped
  bloaty python.stripped 
  echo
  echo ovm2.stripped
  bloaty ovm2.stripped

  # Supports diffs.  The one after -- is the base.
  echo
  echo SECTIONS diff
  bloaty ovm2.stripped -- python.stripped

  # _PyUnicodeUCS2_ToNumeric is 17.7 Ki bigger.  And then there are 560K of
  # [Other]?  Is that due to the compiler or what?
  echo
  echo SYMBOLS diff
  bloaty -d symbols ovm2 -- python
  echo

  ls -l python.stripped ovm2.stripped

  popd
}

# 604 Ki of .text and 122 Ki of .rodata.

# ovm2 is 786 Ki of .text, 223 Ki o .rotdata, and 197 Ki of .data.
# We're in spitting distance.  Is it unicode data?

bash-size() {
  bloaty /bin/bash
  echo
  ls -l /bin/bash
}

# ZSH is smaller, only 495 KiB .textand 41 KiB .rodata.  692 KB data size.
zsh-size() {
  bloaty /usr/bin/zsh
  echo
  ls -l $(readlink -f /usr/bin/zsh)
}

"$@"
