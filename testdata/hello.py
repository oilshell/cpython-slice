#!/usr/bin/python
"""
hello.py
"""

print('Hello from hello.py')

import sys
print(sys.path)
#print(sys.argv)

import lib


def Busy(n):
  s = 0
  for i in xrange(n):
    s += i
  print(s)


def main(argv):
  if argv:
    n = int(argv[0])
  else:
    n = 100
  Busy(n)

# Hm ovm2 doesn't have argv.  Not initialized correctly.
main(sys.argv[1:])
