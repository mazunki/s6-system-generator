#!/bin/sh
set -eu

BIN="$(dirname "$(realpath "$0")")"
. "${BIN}"/paths.sh
. "${BIN}"/fmt.sh

"${BIN}"/clean.sh
"${BIN}"/generate.sh
"${BIN}"/s6-recompile-init

