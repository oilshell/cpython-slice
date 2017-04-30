#!/usr/bin/python
"""
module_manifest.py
"""

import glob
import re
import sys


PY_RE = re.compile(r'Lib/(.*)\.py')

PURE_C_RE = re.compile(r'Modules/(.*)module\.c')
HELPER_C_RE = re.compile(r'Modules/_(.*)\.c')


def main(argv):
  # module name -> list of paths to include
  module_paths = {}

  for py_path in glob.glob('Lib/*.py'):
    m = PY_RE.match(py_path)
    print m.group(1), py_path

  for c_path in glob.glob('Modules/*.c'):
    m = PURE_C_RE.match(c_path)
    if m:
      print m.group(1), c_path
      continue

    m = HELPER_C_RE.match(c_path)
    if m:
      print m.group(1), c_path



if __name__ == '__main__':
  try:
    main(sys.argv)
  except RuntimeError as e:
    print >>sys.stderr, 'FATAL: %s' % e
    sys.exit(1)
