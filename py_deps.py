#!/usr/bin/python -S
"""
py_deps.py

Simple way of finding the transitive closure of Python imports.  The main module
is imported and sys.modules is inspected before and after.  This way we use the
exact logic that the Python interpreter does.

Usage:
  PYTHONPATH=... py_imports.py <main module 1> <main module 2>

IMPORTANT: This script is run with -S so that system libraries aren't found.
Instead, we prefer to set PYTHONPATH to point at uncompressed source tarballs
for each library.
"""

import sys
OLD_MODULES = dict(sys.modules)  # Make a copy

# TODO: Does this import mess it up?  Don't really need it.
#import os
#import optparse


class Error(Exception):
  pass


def log(msg, *args):
  if args:
    msg = msg % args
  print >>sys.stderr, '\t', msg


def ImportModules(modules, old_modules):
  """Yields (module name, absolute path) pairs."""

  main_module = None
  for i, module_name in enumerate(modules):
    log('Importing %r', module_name)
    try:
      __import__(module_name)
    except ImportError, e:
      log('Error importing %r with sys.path %r', module_name, sys.path)
      # TODO: print better error.
      raise

  new_modules = sys.modules
  log('After importing: %d modules', len(new_modules))

  for name in sorted(new_modules):
    if name in old_modules:
      continue  # exclude old modules

    module = new_modules[name]

    filename = getattr(module, '__file__', None)

    # For some reason, there are entries like:
    # 'pan.core.os': None in sys.modules.  Here's a hack to get rid of them.
    if module is None:
      continue
    # Not sure why, but some stdlib modules don't have a __file__ attribute,
    # e.g. "gc", "marshal", "thread".  Doesn't matter for our purposes.
    if filename is None:
      continue
    yield name, filename


def ModuleToRelativePath(modules, main_module):
  """Yields (type, absolute input path, archive path) pairs."""
  for module, filename in modules:
    if module:
      if module == main_module:
        file_type = 'x'
      else:
        file_type = 'f'
      #print 'OLD', module, filename
      num_parts = module.count('.') + 1
      i = len(filename)
      # Do it once more in this case
      if filename.endswith('/__init__.py'):
        i = filename.rfind('/', 0, i)
      for _ in xrange(num_parts):
        i = filename.rfind('/', 0, i)
      #print i, filename[i+1:]
      rel_path = filename[i+1:]

      # .pyc file
      yield file_type, filename, rel_path

      assert filename.endswith('.pyc'), filename

      # .py file needed for tracebacks
      yield file_type, filename[:-1], rel_path[:-1]

    else:
      yield 'f', filename, filename


# TODO: Get rid of this?
def CreateOptionsParser():
  parser = optparse.OptionParser()
  return parser


def main(argv):
  """Returns an exit code."""

  #(opts, argv) = CreateOptionsParser().parse_args(argv)
  #if not argv:
  #  raise Error('No modules specified.')

  main_module = argv[0]
  log('Before importing: %d modules', len(OLD_MODULES))
  #os_file = os.__file__
  #stdlib_dir = os.path.dirname(os_file) + '/'

  modules = ImportModules(argv, OLD_MODULES)

  out = ModuleToRelativePath(modules, main_module)
  for file_type, input_path, archive_path in out:
    #if input_path.startswith(stdlib_dir):
    #  continue
    print '%s %s' % (input_path, archive_path)


if __name__ == '__main__':
  try:
    sys.exit(main(sys.argv[1:]))
  except Error, e:
    print >> sys.stderr, 'py-deps:', e.args[0]
    sys.exit(1)
