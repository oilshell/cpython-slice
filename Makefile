# Build App Bundles.

# Needed for rules with '> $@'.  Does this always work?
.DELETE_ON_ERROR:

# Intermediate targets aren't automatically deleted.
.SECONDARY:

# _release/oil.tar
all: _bin/hello.bundle _bin/oil.bundle _release/hello.tar

dirs:
	mkdir -p _bin _release _build/hello _build/oil

clean:
	rm -r -f _bin _build/hello _build/oil
	rm -f _build/runpy-*.txt _build/c-module-manifest.txt
	build/actions.sh clean-pyc

.PHONY: all dirs clean

PY27 = Python-2.7.13

# What files correspond to each C module.
# TODO:
# - Where to put -l z?  (Done in Modules/Setup.dist)
_build/c-module-manifest.txt: build/module_manifest.py
	build/actions.sh module-manifest > $@

# Python and C dependencies of runpy.
# NOTE: This is done with a pattern rule because of the "multiple outputs"
# problem in Make.
_build/runpy-%.txt: build/runpy_modules.py
	build/actions.sh runpy-modules _build

#
# Hello App.  Everything below here is app-specific.
#

# C module dependencies
-include _build/hello/ovm.d

# What Python module to run.
_build/hello/main_name.c:
	echo 'char* MAIN_NAME = "hello";' > $@

# Dependencies calculated by importing main.  The guard is because ovm.d
# depends on it.  Is that correct?  We'll skip it before 'make dirs'.
_build/hello/discovered-%.txt: $(HELLO_SRCS) py_deps.py
	test -d _build/hello && PYTHONPATH=testdata build/actions.sh py-deps hello _build/hello

# NOTE: We could use src/dest paths pattern instead of _build/app?
#
# TODO:
# - Deps need to be better.  Depend on .pyc and .py.    I guess
#   py-deps hello will compile the .pyc files.  Don't need a separate action.
#   %.pyc : %py
_build/hello/bytecode.zip: $(HELLO_SRCS) \
                         hello-manifest.txt \
                         _build/hello/discovered-py.txt \
                         _build/runpy-py.txt
	build/make_zip.py $@ \
	  hello-manifest.txt _build/hello/discovered-py.txt _build/runpy-py.txt

#
# Oil
#

# C module dependencies
-include _build/oil/ovm.d

_build/oil/main_name.c:
	echo 'char* MAIN_NAME = "bin.oil";' > $@

# Dependencies calculated by importing main.
_build/oil/discovered-%.txt: py_deps.py
	test -d _build/hello && PYTHONPATH=~/git/oil build/actions.sh py-deps bin.oil _build/oil

# TODO: Need $(OIL_SRCS) here?
_build/oil/bytecode.zip: oil-manifest.txt \
	                     _build/oil/discovered-py.txt \
                       _build/runpy-py.txt
	build/make_zip.py $@ \
		oil-manifest.txt _build/oil/discovered-py.txt _build/runpy-py.txt

#
# App-Independent Pattern Rules.
#

# Regenerate dependencies.  But only if we made the app dirs.
_build/%/ovm.d: _build/%/discovered-c.txt
	build/actions.sh make-dotd $* $^ > $@

# A trick: remove the first dep to form the lists.  You can't just use $^
# because './module_paths.py' is rewritten to 'module_paths.py'.
_build/%/module-paths.txt: \
	build/module_paths.py _build/c-module-manifest.txt _build/%/discovered-c.txt 
	build/module_paths.py $(filter-out $<,$^) > $@

_build/%/all-c-modules.txt: static-c-modules.txt _build/%/discovered-c.txt
	build/actions.sh join-modules $^ > $@

# Per-app extension module initialization.
_build/%/module_init.c: $(PY27)/Modules/config.c.in _build/%/all-c-modules.txt
	cat _build/$*/all-c-modules.txt | xargs build/actions.sh gen-module-init > $@

# Release build.
# This depends on the static modules
_build/%/ovm: _build/%/module_init.c _build/%/main_name.c _build/%/module-paths.txt
	build/compile.sh build-opt $@ $^

# Fast build, with symbols for debugging.
_build/%/ovm-dbg: _build/%/module_init.c _build/%/main_name.c _build/%/module-paths.txt
	build/compile.sh build-dbg $@ $^

# Coverage, for paring down the files that we build.
# TODO: Hook this up.
_build/%/ovm-cov: _build/%/module_init.c _build/%/main_name.c _build/%/module-paths.c
	# TODO: cov flags
	build/compile.sh build $@ $^

# Pattern rule to make bundles.
# NOTE: Using ovm-dbg for now.
_bin/%.bundle: _build/%/ovm-dbg _build/%/bytecode.zip
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

# TODO:
# - Why does putting module_paths.txt here mess it up?
_release/%.tar: _build/%/bytecode.zip \
	              _build/%/module_init.c \
								_build/%/main_name.c
	build/compile.sh make-tar $* $@

# For debugging
print-%:
	@echo $*=$($*)
