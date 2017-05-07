#!/usr/bin/python -S
"""
py_deps_test.py: Tests for py_deps.py
"""

__author__ = 'Andy Chu'


import sys
import unittest

import py_deps  # module under test


class PyDepsTest(unittest.TestCase):

  def testModules(self):
    pairs = [ ( 'poly.util',
               'poly/util.py'),
              ( 'core.libc',
                '/git/oil/core/libc.so'),
              ( 'simplejson', 
                '/home/andy/dev/simplejson-2.1.5/simplejson/__init__.py')
              ]
    py_deps.PrintManifest(pairs, sys.stdout, sys.stdout)


if __name__ == '__main__':
  unittest.main()
