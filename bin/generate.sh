#!/bin/sh
set -eu

BIN="$(dirname "$(realpath "$0")")"
. "${BIN}"/paths.sh
. "${BIN}"/fmt.sh

add_to_tree() {
	local group="$1"
	local service="$2"
	local bundle_dir="${S6_BUNDLE_HOME}/${group}"

	mkdir -p "${bundle_dir}/contents.d"
	test -f "${bundle_dir}" || {
		printf 'bundle' | tee "${bundle_dir}/type" >/dev/null
	}
	touch "${bundle_dir}/contents.d/${service}"
}

longrunning() {
	name=$1; shift;
	"${BIN}"/s6-new-service.sh "${group}:${name}" "$@"
	add_to_tree "${group}" "${name}"
}
oneshot() {
	local name=$1; shift;
	"${BIN}"/s6-new-service.sh --oneshot "${group}:${name}" "$@"
	add_to_tree "${group}" "${name}"
}
bundle() {
	local name=$1; shift;
	"${BIN}"/s6-new-service.sh --bundle "${group}:${name}" -- "$@"
	add_to_tree "${group}" "${name}"
}

test -f "${S6_SERVICE_DECLARATIONS}" || {
	printf '%s\n' "$(fmt_warn "${S6_SERVICE_DECLARATIONS}") $(fmt_err "doesn't exist. We need it to create services")"
	exit 1;
}
test ! -e "${S6_SERVICE_HOME}" || {
	printf '%s\n' "$(fmt_warn "${S6_SERVICE_HOME}") $(fmt_err "already exists. Consider deleting it:")" "$(fmt_info ": rm -r ${S6_SERVICE_HOME}")"
	exit 1;
}

. "${S6_SERVICE_DECLARATIONS}"

printf '%s\n' "$(fmt_info "All services have been created successfully.")" "$(fmt_info "Hopefully.")" "$(fmt_ok "This fills you with determination.")"

