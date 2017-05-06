
all: _bin/hello.bundle _release/hello.tar

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
	./actions.sh default-modules _tmp

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
	mkdir -p _bin _release _tmp/hello/Lib _tmp/hello/app

.PHONY: prepare-hello


# This is based on importing it
_tmp/hello/c-modules.txt: $(HELLO_SRCS)
	echo TODO

# This is based on importing it
_tmp/hello/py-modules.txt: $(HELLO_SRCS)
	./actions.sh hello-deps > $@

# NOTE: We could use src/dest paths pattern instead of _tmp/app?
#
# TODO:
# - Deps need to be better.  Depend on .pyc and .py.    I guess
#   py-deps hello will compile the .pyc files.  Don't need a separate action.
#   %.pyc : %py
# - Also __main__ needs to be handled, not in run.sh?
_tmp/hello/bytecode.zip: $(HELLO_SRCS) \
                         _tmp/hello/py-modules.txt \
                         _tmp/py.default-modules.txt
	./make_zip.py $@ _tmp/hello/py-modules.txt _tmp/py.default-modules.txt

#.PHONY: _tmp/app/runpy.pyc

# This is now per-app
_tmp/hello/module_init.c: $(PY27)/Modules/config.c.in ModulesSetup
	./slice.sh mod-setup $@

# Release build.
# This depends on the static modules
_tmp/%/ovm: _tmp/%/module_init.c
	./slice.sh build $@ _tmp/$*/module_init.c -O3

# Fast build, with symbols for debugging.
_tmp/%/ovm-dbg: _tmp/%/module_init.c
	./slice.sh build $@ _tmp/$*/module_init.c

# Coverage, for paring down the files that we build.
_tmp/%/ovm-cov: _tmp/%/module_init.c
	./slice.sh build $@ _tmp/$*/module_init.c  # TODO: cov flags

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
	rm -r -f _bin _tmp/hello

# For debugging
print-%:
	@echo $*=$($*)
