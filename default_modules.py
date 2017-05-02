#!/usr/bin/python -S
"""
base_modules.py

NOTE -S above
"""

import sys  # 15 modules
#import os  #  31 modules
import runpy  # 34 modules
#import zipimport  # still only 34

#import json
#import fcntl


# Python modules get names here.
def main(argv):
  path_prefix = argv[1]

  py_out_path = path_prefix + '/py.default-modules.txt'
  c_out_path = path_prefix + '/c.default-modules.txt'

  with open(py_out_path, 'w') as py_out, open(c_out_path, 'w') as c_out:
    for name in sorted(sys.modules):
      mod = sys.modules[name]
      if name in ('__builtin__', '__main__'):
        continue

      #if '(built-in)' in str(mod):
      #  continue
      try:
        filename = mod.__file__
      except AttributeError:
        filename = None
      #if filename is None:
      #  continue

      # I think this is caught elsewhere
      if filename and filename.endswith('.so'):
        print '!!!'

      if filename and filename.endswith('.pyc'):
        print >>py_out, name, filename
      else:
        print >>c_out, name
      #filename = getattr(mod, '__file__', None)
  print >>sys.stderr, '-- Wrote %s and %s' % (py_out_path, c_out_path)


if __name__ == '__main__':
  try:
    main(sys.argv)
  except RuntimeError as e:
    print >>sys.stderr, 'FATAL: %s' % e
    sys.exit(1)
