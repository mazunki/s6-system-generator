#!/bin/sh
set -eu

HERE="$(dirname "$(realpath "$0")")"
. "${HERE}"/paths.sh
. "${HERE}"/fmt.sh

rm -r "${S6_SERVICE_HOME}" "${S6_BUNDLE_HOME}"

