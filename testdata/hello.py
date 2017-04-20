#!/usr/bin/python
from __future__ import print_function
"""
hello.py
"""

import sys


def main(argv):
  print('Hello from hello.py')


if __name__ == '__main__':
  try:
    main(sys.argv)
  except RuntimeError as e:
    print >>sys.stderr, 'FATAL: %s' % e
    sys.exit(1)
