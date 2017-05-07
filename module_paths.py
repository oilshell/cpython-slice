#!/usr/bin/python
"""
module_paths.py
"""

import sys


def main(argv):
  manifest_path = argv[1]
  discovered = argv[2]

  manifest = {}
  with open(manifest_path) as f:
    for line in f:
      line = line.strip()
      mod_name, rel_path = line.split(None, 2)
      manifest[mod_name] = rel_path

  #print manifest
  with open(discovered) as f:
    for line in f:
      line = line.strip()
      mod_name, _ = line.split(None, 2)
      # KeyError
      print manifest[mod_name]


if __name__ == '__main__':
  try:
    main(sys.argv)
  except RuntimeError as e:
    print >>sys.stderr, 'FATAL: %s' % e
    sys.exit(1)
