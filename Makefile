
all: _bin/hello.bundle _bin/hello.tar.xz

PY27 = Python-2.7.13

# What files correspond to each C module.
# TODO: How to express dependency on the file system or on a directory?
#       This might not belong here at all?
_tmp/c-module-manifest.txt:
	./actions.sh  module-manifest > $@

# C modules that should be statically linked in any binary.  This comes from
# importing runpy.  NOTE: This is done with a pattern rule because of the
# "multiple outputs" problem in Make.
#
# TODO:
# - add the list in Modules/Setup.dist (pwd, _sre)
# 
_tmp/%.default-modules.txt: default_modules.py
	./default_modules.py _tmp

# pyconfig.in.h: freeze it

#
# Hello App.  Everything below here is app-specific.
#

# TODO: Could use $(shell find here.)

HELLO_SRCS := testdata/hello.py testdata/lib.py 
# Substitute?
HELLO_PYC := TODO

PY_SRCS := $(shell find $(PY27) -name '*.[ch]')

prepare-hello:
	mkdir -p _tmp/hello/Lib _tmp/hello/app

.PHONY: prepare-hello

# Compile app dependencies
_tmp/hello/Lib/%.pyc:
	$(PY27)/python -S -c 'import $*'
	cp -v $(PY27)/Lib/$*.pyc _tmp/hello/Lib

# Compile app files
# TODO: You can rely on py_deps to do this?
_tmp/hello/app/%.pyc: testdata/%.py
	cd testdata && ../$(PY27)/python -S -c 'import $*'
	cp -v testdata/$*.pyc _tmp/hello/app

# Wow I didn't realize this was a bad idea.
# http://stackoverflow.com/questions/5873025/heredoc-in-a-makefile
#
# The problem with \ is that it tries to put it all on one line and parse more
# words!

_tmp/hello/app/__main__.py:
	echo TODO > $@

# Hm this doesn't built itd!
_tmp/hello/app/__main__.pyc: _tmp/hello/app/__main__.py
	cd _tmp/hello/app && python -c 'import __main__'

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
