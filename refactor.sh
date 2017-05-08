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
  sed -i 's/module_manifest/module_toc/g' Makefile build/*.{py,sh}
  sed -i 's/module-manifest/module-toc/g' Makefile build/*.{py,sh}
}

"$@"
