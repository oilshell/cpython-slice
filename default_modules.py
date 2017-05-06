#!/usr/bin/python -S
"""
default_modules.py

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

  runpy_path = runpy.__file__
  i = runpy_path.rfind('/')
  assert i != -1, runpy_path
  stdlib_dir = runpy_path[ : i+1]  # include trailing slash
  stdlib_dir_len = len(stdlib_dir)

  #print 'STDLIB', stdlib_dir
  #return

  with open(py_out_path, 'w') as py_out, open(c_out_path, 'w') as c_out:
    for name in sorted(sys.modules):
      mod = sys.modules[name]
      if name in ('__builtin__', '__main__'):
        continue

      #if '(built-in)' in str(mod):
      #  continue
      try:
        full_path = mod.__file__
      except AttributeError:
        full_path = None
      #if filename is None:
      #  continue

      # I think this is caught elsewhere
      if full_path and full_path.endswith('.so'):
        print '!!!'

      if full_path and full_path.endswith('.pyc'):
        py_path = full_path[:-1]
        #print('F', full_path, stdlib_dir)
        if full_path.startswith(stdlib_dir):
          rel_path = py_path[stdlib_dir_len:]
          #print('REL', rel_path)
        else:
          rel_path = py_path
      
        #print >>py_out, name, filename
        print >>py_out, py_path, rel_path
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
