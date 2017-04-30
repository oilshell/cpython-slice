#!/usr/bin/python
"""
hello.py
"""

print('Hello from hello.py')

import os
import sys

print 'sys.path:', sys.path
print 'sys.argv:', sys.argv
print 'hello _OVM_IS_BUNDLE', os.getenv('_OVM_IS_BUNDLE')

import lib

#import zipfile 
if os.getenv('_OVM_IS_BUNDLE') == '1':
  if 0:
    print('ZIP')
    z = zipfile.ZipFile(sys.argv[0])
    print z.infolist()


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
