#!/bin/bash
#
# Usage:
#   ./deb.sh <function name>

set -o nounset
set -o pipefail
set -o errexit

source common.sh

readonly DEB_PY_DEFAULTS=python-defaults/python-defaults-2.7.5
readonly DEB_PY27=python2.7/python2.7-2.7.6

# for debuild
devscripts() {
  sudo apt-get install devscripts
}

# See the python_defaults/control dir
deps-python-defaults() {
  mkdir -p python-defaults
  cd python-defaults
  apt-get source python-defaults
  sudo apt-get build-dep python-defaults
}

# Rebuild source package
# only took 11 seconds?  Oh this jus downloaded a bunch of debs.
# does dh_make do caching?  Or is this a special package?

# python:
# "This package is a dependency package, which depends on Debian's default Python
# version (currently v2.7)."

# python-minimal:

# This package contains the interpreter and some essential modules.  It's used
# in the boot process for some basic tasks.
# See /usr/share/doc/python2.7-minimal/README.Debian for a list of the modules
# contained in this package.

build-python-defaults() {
  pushd $DEB_PY_DEFAULTS
  # -b : only build binary package
  time debuild -us -uc || true
  popd
}

minimal-docs() {
  #less python-defaults/python-defaults-2.7.5/debian/python-minimal/usr/share/doc/python-minimal/README.Debian
  less /usr/share/doc/python2.7-minimal/README.Debian 
}

#
# Python 2.7
#

# See the python_defaults/control dir
# Gah this installs a ton of build dependencies.  Even more than
# python-defaults.
deps-python27() {
  mkdir -p python2.7
  cd python2.7
  apt-get source python2.7
  sudo apt-get build-dep python2.7
}

# This also runs a lot of tests!
# Some tests seem to hose the machine a bit, perhaps multiprocessing.
build-python27() {
  pushd $DEB_PY27
  # -b : only build binary package
  time debuild -us -uc || true
  popd
}

# I think I cancelled the tests and there were no packages generated in the 
# debian/ dir.  But still some binaries.

# build-static - 11M, not dynamically linked to much.
# build-debug - 5.9M
#
# build-shared - 10K, linked to libpython2.7.so.1.0
# build-shdbug - 9.7K, linked to libpython2.7_d.so.1.0

py27-stats() {
  find python2.7/ -name python | xargs -n 1 -- $0 bin-stats
}

# This is a 1300 line makefile to do all the logic.  I think minimal is just
# different packages -- NOT a smaller binary.
minimal() {
  wc -l $DEB_PY27/debian/rules
  less $DEB_PY27/debian/rules
}

# How to check without building:

# https://packages.debian.org/jessie/python2.7-minimal

download-python2.7-minimal() {
  mkdir -p _tmp/deb
  wget --directory _tmp/deb http://ftp.us.debian.org/debian/pool/main/p/python2.7/python2.7-minimal_2.7.9-2+deb8u1_amd64.deb
}

# unpacked it manually
# Hm actually it's 3.7 MB stripped.  But my own source build is 2.0 MB
# stripped?
# Links against pthread and so forth.  Not sure what the difference is.
prebuilt-py27-stats() {
  bin-stats _tmp/deb/usr/bin/python2.7
}

"$@"
