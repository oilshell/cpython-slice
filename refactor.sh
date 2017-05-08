#!/bin/bash
#
# Usage:
#   ./refactor.sh <function name>

set -o nounset
set -o pipefail
set -o errexit

one() {
  sed -i 's/module_paths/module_srcs/g' Makefile build/*.{py,sh}
  sed -i 's/module-paths/module-srcs/g' Makefile build/*.{py,sh}
}

two() {
  sed -i 's/c-module-manifest/module-manifest/g' Makefile build/*.{py,sh}
}

three() {
  sed -i 's/module_manifest/c_module_toc/g' Makefile build/*.{py,sh}
  sed -i 's/module-manifest/c-module-toc/g' Makefile build/*.{py,sh}
}

four() {
  sed -i 's/runpy-/runpy-deps-/g' Makefile build/*.{py,sh}
}

five() {
  sed -i 's/-deps-deps/-deps/g' Makefile build/*.{py,sh}
}

six() {
  sed -i 's/all-c-modules/all-deps-c/g' Makefile build/*.{py,sh}
}

seven() {
  sed -i 's/module_srcs/c_module_srcs/g' Makefile build/*.{py,sh}
  sed -i 's/module-srcs/c_module-srcs/g' Makefile build/*.{py,sh}
}

eight() {
  sed -i 's/c_module-srcs/c-module-srcs/g' Makefile build/*.{py,sh}
}


"$@"
