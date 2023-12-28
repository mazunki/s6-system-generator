#!/bin/sh
set -eu

HERE="$(dirname "$(realpath "$0")")"
. "${HERE}"/paths.sh
. "${BIN}"/fmt.sh

rm -rf "${S6_COMPILE_HOME}"/*
rm -rf "${S6_SERVICE_HOME}" "${S6_BUNDLE_HOME}"

