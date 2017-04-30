#!/usr/bin/python -S
"""
base_modules.py

NOTE -S above
"""

import sys  # 15 modules
import os  #  31 modules
import runpy  # 34 modules
# Hm this brings in the thread module, geez.
#import zipfile  # 62 modules
import zipimport  # still only 34


def main(argv):
  for k, v in sys.modules.iteritems():
    print k, v


if __name__ == '__main__':
  try:
    main(sys.argv)
  except RuntimeError as e:
    print >>sys.stderr, 'FATAL: %s' % e
    sys.exit(1)
