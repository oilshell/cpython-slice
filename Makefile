
all: _bin/hello.bundle _bin/hello.tar.xz

PY27 = Python-2.7.13

# What files correspond to each C module.
# TODO: How to express dependency on the file system or on a directory?
#       This might not belong here at all?
_tmp/c-module-manifest.txt:
	./actions.sh  module-manifest > $@

# This comes from importing runpy, and also the list in Modules/Setup.dist.
# Some C modules should be statically linked.
_tmp/default-py-modules.txt _tmp/default-c-modules.txt: default_modules.py
	./default_modules.py TODO

# pyconfig.in.h: freeze it

#
# Hello App.  Everything below here is app-specific.
#

# TODO: Could use $(shell find here.)

HELLO_SRCS := testdata/hello.py testdata/lib.py 
# Substitute?
HELLO_PYC := TODO

PY_SRCS := $(shell find $(PY27) -name '*.[ch]')

# Compile app dependencies
_tmp/hello/Lib/runpy.pyc:
	$(PY27)/python -S -c 'import runpy'
	cp -v $(PY27)/Lib/runpy.pyc _tmp/app

# Compile app files
_tmp/hello/app/%.pyc: testdata/%.pyc
	$(PY27)/python -S -c 'import runpy'
	cp -v $(PY27)/Lib/runpy.pyc _tmp/app

# NOTE: We could use src/dest paths pattern instead of _tmp/app?
# TODO: Do we need a tool to merge Lib/ and app/?  I guess there will be no
# conflicts because of the sys.modules cache.
_tmp/hello/py.zip: $(HELLO_SRCS) _tmp/app/runpy.pyc
	./run.sh build-hello-zip

#.PHONY: _tmp/app/runpy.pyc

# This is based on importing it
_tmp/hello/c-modules.txt: $(HELLO_SRCS)
	echo TODO

# This is based on importing it
_tmp/hello/py-modules.txt: $(HELLO_SRCS)
	echo TODO

# This is now per-app
_tmp/hello/module_init.c: $(PY27)/Modules/config.in.c
	echo TODO

# Release build.
# This depends on the static modules
_tmp/hello/ovm: _tmp/hello/config.c
	# TODO: Should run ./slice.sh build.  That should accept variations.
	cp Python-2.7.13/ovm2 $@

# Fast build, with symbols for debugging.
_tmp/hello/ovm-dbg: _tmp/hello/config.c
	# TODO: Should run ./slice.sh build.  That should accept variations.
	cp Python-2.7.13/ovm2 $@

# Coverage, for paring down the files that we build.
_tmp/hello/ovm-cov: _tmp/hello/config.c
	# TODO: Should run ./slice.sh build.  That should accept variations.
	cp Python-2.7.13/ovm2 $@

_bin/hello.bundle: _tmp/hello/ovm _tmp/hello/py.zip
	cat $^ > $@
	chmod +x $@

# Makefile, selected .c files, selected .py files, app source.
# I guess it should look like the repo?
# hello.tar/
#   Makefile
#   testdata/
#     hello.py
#     hello.pyc
#     lib.py
#     lib.pyc
#   Python-2.7.13
#     Lib/
#     Modules/
#     Python/
#     Objects/  # Which ones?  Use coverage I guess?
#     Include/  # Which ones? strace?
_bin/hello.tar.xz: _tmp/hello/py.zip
	echo TODO

clean:
	rm -r -f _bin _tmp/hello

# For debugging
print-%:
	@echo $*=$($*)
