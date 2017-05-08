# Build App Bundles.

# Needed for rules with '> $@'.  Does this always work?
.DELETE_ON_ERROR:

# Intermediate targets aren't automatically deleted.
.SECONDARY:

# _release/oil.tar
all: _bin/hello.bundle _bin/oil.bundle _release/hello.tar

dirs:
	mkdir -p _bin _release _tmp/hello _tmp/oil

clean:
	rm -r -f _bin _tmp/hello _tmp/oil
	rm -f _tmp/runpy-*.txt _tmp/c-module-manifest.txt
	build/actions.sh clean-pyc

.PHONY: all dirs clean

PY27 = Python-2.7.13

# What files correspond to each C module.
# TODO:
# - Where to put -l z?  (Done in Modules/Setup.dist)
_tmp/c-module-manifest.txt: build/module_manifest.py
	build/actions.sh module-manifest > $@

# Python and C dependencies of runpy.
# NOTE: This is done with a pattern rule because of the "multiple outputs"
# problem in Make.
_tmp/runpy-%.txt: build/runpy_modules.py
	build/actions.sh runpy-modules _tmp

#
# Hello App.  Everything below here is app-specific.
#

# C module dependencies
-include _tmp/hello/ovm.d

# What Python module to run.
_tmp/hello/main_name.c:
	echo 'char* MAIN_NAME = "hello";' > $@

# Dependencies calculated by importing main.  The guard is because ovm.d
# depends on it.  Is that correct?  We'll skip it before 'make dirs'.
_tmp/hello/discovered-%.txt: $(HELLO_SRCS) py_deps.py
	test -d _tmp/hello && PYTHONPATH=testdata build/actions.sh py-deps hello _tmp/hello

# NOTE: We could use src/dest paths pattern instead of _tmp/app?
#
# TODO:
# - Deps need to be better.  Depend on .pyc and .py.    I guess
#   py-deps hello will compile the .pyc files.  Don't need a separate action.
#   %.pyc : %py
_tmp/hello/bytecode.zip: $(HELLO_SRCS) \
                         hello-manifest.txt \
                         _tmp/hello/discovered-py.txt \
                         _tmp/runpy-py.txt
	./make_zip.py $@ \
	  hello-manifest.txt _tmp/hello/discovered-py.txt _tmp/runpy-py.txt

#
# Oil
#

# C module dependencies
-include _tmp/oil/ovm.d

_tmp/oil/main_name.c:
	echo 'char* MAIN_NAME = "bin.oil";' > $@

# Dependencies calculated by importing main.
_tmp/oil/discovered-%.txt: py_deps.py
	test -d _tmp/hello && PYTHONPATH=~/git/oil build/actions.sh py-deps bin.oil _tmp/oil

# TODO: Need $(OIL_SRCS) here?
_tmp/oil/bytecode.zip: oil-manifest.txt \
	                     _tmp/oil/discovered-py.txt \
                       _tmp/runpy-py.txt
	./make_zip.py $@ \
		oil-manifest.txt _tmp/oil/discovered-py.txt _tmp/runpy-py.txt

#
# App-Independent Pattern Rules.
#

# Regenerate dependencies.  But only if we made the app dirs.
_tmp/%/ovm.d: _tmp/%/discovered-c.txt
	build/actions.sh make-dotd $* $^ > $@

# A trick: remove the first dep to form the lists.  You can't just use $^
# because './module_paths.py' is rewritten to 'module_paths.py'.
_tmp/%/module-paths.txt: \
	build/module_paths.py _tmp/c-module-manifest.txt _tmp/%/discovered-c.txt 
	build/module_paths.py $(filter-out $<,$^) > $@

_tmp/%/all-c-modules.txt: static-c-modules.txt _tmp/%/discovered-c.txt
	build/actions.sh join-modules $^ > $@

# Per-app extension module initialization.
_tmp/%/module_init.c: $(PY27)/Modules/config.c.in _tmp/%/all-c-modules.txt
	cat _tmp/$*/all-c-modules.txt | xargs build/actions.sh gen-module-init > $@

# Release build.
# This depends on the static modules
_tmp/%/ovm: _tmp/%/module_init.c _tmp/%/main_name.c _tmp/%/module-paths.txt
	build/compile.sh build-opt $@ $^

# Fast build, with symbols for debugging.
_tmp/%/ovm-dbg: _tmp/%/module_init.c _tmp/%/main_name.c _tmp/%/module-paths.txt
	build/compile.sh build-dbg $@ $^

# Coverage, for paring down the files that we build.
# TODO: Hook this up.
_tmp/%/ovm-cov: _tmp/%/module_init.c _tmp/%/main_name.c _tmp/%/module-paths.c
	# TODO: cov flags
	build/compile.sh build $@ $^

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

# TODO:
# - Why does putting module_paths.txt here mess it up?
_release/%.tar: _tmp/%/bytecode.zip \
	              _tmp/%/module_init.c \
								_tmp/%/main_name.c
	build/compile.sh make-tar $* $@

# For debugging
print-%:
	@echo $*=$($*)
