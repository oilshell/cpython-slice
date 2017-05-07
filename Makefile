# Build App Bundles.

# Needed for rules with '> $@'.  Does this always work?
.DELETE_ON_ERROR:

# Intermediate targets aren't automatically deleted.
.SECONDARY:

all: _bin/hello.bundle _bin/oil.bundle _release/hello.tar

dirs:
	mkdir -p _bin _release _tmp/hello _tmp/oil

.PHONY: dirs

PY27 = Python-2.7.13

# What files correspond to each C module.
# TODO:
# - How to express dependency on the file system or on a directory?
#   This might not belong here at all?
# - Where to put -l z?

_tmp/c-module-manifest.txt: module_manifest.py
	./actions.sh module-manifest > $@

# Python and C dependencies of runpy.
# NOTE: This is done with a pattern rule because of the "multiple outputs"
# problem in Make.
#
# TODO:
# - add the list in Modules/Setup.dist (pwd, _sre)
# 
_tmp/runpy-%.txt: default_modules.py
	./actions.sh runpy-modules _tmp

# pyconfig.in.h: freeze it

#
# Hello App.  Everything below here is app-specific.
#

HELLO_SRCS := testdata/hello.py testdata/lib.py 

PY_SRCS := $(shell find $(PY27) -name '*.[ch]')

#
# Hello App
#

# C module dependencies
-include _tmp/hello/ovm.d

_tmp/hello/main_name.c:
	echo 'char* MAIN_NAME = "hello";' > $@

# Dependencies calculated by importing main.
_tmp/hello/discovered-%.txt: $(HELLO_SRCS) py_deps.py
	PYTHONPATH=testdata ./actions.sh py-deps hello _tmp/hello

# NOTE: We could use src/dest paths pattern instead of _tmp/app?
#
# TODO:
# - Deps need to be better.  Depend on .pyc and .py.    I guess
#   py-deps hello will compile the .pyc files.  Don't need a separate action.
#   %.pyc : %py
_tmp/hello/bytecode.zip: $(HELLO_SRCS) \
                         _tmp/hello/discovered-py.txt \
                         _tmp/runpy-py.txt
	./make_zip.py $@ _tmp/hello/discovered-py.txt _tmp/runpy-py.txt

#
# Oil
#

# C module dependencies
-include _tmp/oil/ovm.d

_tmp/oil/main_name.c:
	echo 'char* MAIN_NAME = "bin.oil";' > $@

# Dependencies calculated by importing main.
_tmp/oil/discovered-%.txt: py_deps.py
	PYTHONPATH=~/git/oil ./actions.sh py-deps bin.oil _tmp/oil

# TODO: Need $(OIL_SRCS) here?
_tmp/oil/bytecode.zip: _tmp/oil/discovered-py.txt \
                       _tmp/runpy-py.txt
	./make_zip.py $@ _tmp/oil/discovered-py.txt _tmp/runpy-py.txt

#
# Generic
#

# Regenerate dependencies
_tmp/%/ovm.d: _tmp/%/discovered-c.txt
	./actions.sh make-dotd $* $^ > $@

_tmp/%/module-paths.txt: _tmp/c-module-manifest.txt _tmp/%/discovered-c.txt 
	./actions.sh module-paths $^ > $@

_tmp/%/all-c-modules.txt: static-c-modules.txt _tmp/%/discovered-c.txt
	./actions.sh join-modules $^ > $@

# Per-app extension module initialization.
_tmp/%/module_init.c: $(PY27)/Modules/config.c.in _tmp/%/all-c-modules.txt
	cat _tmp/$*/all-c-modules.txt | xargs ./actions.sh gen-module-init > $@

# Release build.
# This depends on the static modules
_tmp/%/ovm: _tmp/%/module_init.c _tmp/%/main_name.c _tmp/%/module-paths.txt
	./slice.sh build-opt $@ $^

# Fast build, with symbols for debugging.
_tmp/%/ovm-dbg: _tmp/%/module_init.c _tmp/%/main_name.c _tmp/%/module-paths.txt
	./slice.sh build-dbg $@ $^

# Coverage, for paring down the files that we build.
_tmp/%/ovm-cov: _tmp/%/module_init.c _tmp/%/main_name.c _tmp/%/module-paths.c
	# TODO: cov flags
	./slice.sh build $@ $^

# Pattern rule to make bundles.
# NOTE: Using ovm-dbg for now.
_bin/%.bundle: _tmp/%/ovm-dbg _tmp/%/bytecode.zip
	cat $^ > $@
	chmod +x $@

# Makefile, selected .c files, selected .py files, app source.
# I guess it should look like the repo?
# hello.tar/
#   Makefile
#   bytecode.zip  # So we don't have to have zip on the machine
#   Python-2.7.13
#     Lib/
#     Modules/
#     Python/
#     Objects/  # Which ones?  Use coverage I guess?
#     Include/  # Which ones? strace?
_release/hello.tar: _tmp/hello/bytecode.zip
	tar --create --directory _tmp/hello bytecode.zip > $@

clean:
	rm -r -f _bin _tmp/hello _tmp/oil
	rm -f _tmp/runpy-*.txt _tmp/c-module-manifest.txt
	./actions.sh clean-pyc

# For debugging
print-%:
	@echo $*=$($*)
