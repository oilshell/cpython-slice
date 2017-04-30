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
import zipimport
if os.getenv('_OVM_IS_BUNDLE') == '1':
  if 0:
    print('ZIP')
    z = zipfile.ZipFile(sys.argv[0])
    print z.infolist()
  else:
    z = zipimport.zipimporter(sys.argv[0])
    print(z)
    print(dir(z))
    # None if we have the module, but no source.
    print('SOURCE', repr(z.get_source('runpy')))
    # TODO: Add a method to get a file?  I think it just imports zlib.
    r = z.get_data('runpy.pyc')
    print('FILE', repr(r))


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
