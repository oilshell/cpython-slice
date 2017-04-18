#!/bin/bash
#
# Usage:
#   ./static.sh <function name>

set -o nounset
set -o pipefail
set -o errexit

source common.sh

# http://ptspts.blogspot.com/2014/06/whats-difference-between-staticpython.html
#
# - Another important difference is that with PyRun you can compile and install
# C extensions, and with StaticPython you can't (even ctypes doesn't work with
# StaticPython). However, many extensions are precompiled: Stackless + greenlet
# + libssl + Tokyo Cabinet + libevent2 + Concurrence + AES + Syncless +
# MessagePack + Gevent MySQL + PyCrypto. 
#
# Yeah this is what I want.  Except I want to eliminate the parser too!


# Is this a second static python?
# https://github.com/bendmorris/static-python
# http://mdqinc.com/blog/2011/08/statically-linking-python-with-cython-generated-modules-and-packages/


download() {
  mkdir -p _static
  wget --directory _static https://raw.githubusercontent.com/pts/staticpython/master/release/python2.7-static

  chmod +x _static/python2.7-static
}

# 7.5 MB
static-stats() {
  bin-stats _static/python2.7-static
}

"$@"
