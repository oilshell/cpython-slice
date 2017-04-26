#!/usr/bin/python
"""
hello.py
"""

print('Hello from hello.py')

import sys
print(sys.path)

import lib


def Busy():
  s = 0
  for i in xrange(10000000):
    s += i
  print(s)

Busy()
  
