#!/usr/bin/python -S
"""
base_modules.py

NOTE -S above
"""

import sys  # 15 modules
#import os  #  31 modules
import runpy  # 34 modules
#import zipimport  # still only 34


# Python modules get names here.
def main(argv):
  for name in sorted(sys.modules):
    mod = sys.modules[name]
    if name in ('__builtin__', '__main__'):
      continue

    #if '(built-in)' in str(mod):
    #  continue
    print name, mod


if __name__ == '__main__':
  try:
    main(sys.argv)
  except RuntimeError as e:
    print >>sys.stderr, 'FATAL: %s' % e
    sys.exit(1)
