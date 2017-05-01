
all: _bin/hello.bundle

PY27 = Python-2.7.13

_bin/ovm:
	# TODO: Should run ./slice.sh build.  That should accept variations.
	cp Python-2.7.13/ovm2 $@

# NOTE: We could use src/dest paths pattern instead of _tmp/app?
_tmp/hello.zip: testdata/hello.py testdata/lib.py _tmp/app/runpy.pyc
	./run.sh build-hello-zip

_tmp/app/runpy.pyc:
	$(PY27)/python -S -c 'import runpy'
	cp -v $(PY27)/Lib/runpy.pyc _tmp/app

#.PHONY: _tmp/app/runpy.pyc

_bin/hello.bundle: _bin/ovm _tmp/hello.zip
	cat $^ > $@
	chmod +x $@

