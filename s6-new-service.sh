#!/bin/sh
set -eu
HERE="$(dirname "$(realpath "$0")")"
. "${HERE}"/paths.sh
. "${HERE}"/fmt.sh

usage() {
    printf 'Usage: %s\n' "$0 <group>:<name_of_service> <command to run> [dependencies...]"
    exit 1
}

if [ $# -ge 1 ]; then
	case $1 in
		-h|--help) usage ;;
		-1|--oneshot) SRV_TYPE=oneshot; shift 1 ;;
		-b|--bundle) SRV_TYPE=bundle; shift 1 ;;
		*) SRV_TYPE=longrun ;;
	esac
fi

if [ $# -lt 2 ]; then
	usage
fi

FULL_SERVICE_NAME="${1}"
SERVICE_NAME="${FULL_SERVICE_NAME##*:}"
SERVICE_GROUP="${FULL_SERVICE_NAME%:*}"
shift

COMMAND=''
NEWLINE=''
for arg; do
	shift;
	if test "${arg}" = '--'; then break; fi
	COMMAND="${COMMAND}${NEWLINE}${arg}"
	NEWLINE=$'\n'
done

: ${DOWN_COMMAND:=true}
printf '%s\n' "Building service $(fmt_info "${FULL_SERVICE_NAME}") with command '$(fmt_debug "${COMMAND}")'"

: ${S6_SERVICE_HOME:=./services}
mkdir -p "${S6_SERVICE_HOME}/${SERVICE_GROUP}"

SERVICE_DO_DIR="${S6_SERVICE_HOME}/${SERVICE_GROUP}/${SERVICE_NAME}-do" 
SERVICE_LOOK_DIR="${S6_SERVICE_HOME}/${SERVICE_GROUP}/${SERVICE_NAME}-look" 

cp -rT "${HERE}/mock/${SRV_TYPE}/do" "${SERVICE_DO_DIR}"
cp -rT "${HERE}/mock/${SRV_TYPE}/look" "${SERVICE_LOOK_DIR}"

COMMAND="${COMMAND//$'\n'/__NEWLINE__}"
find "${SERVICE_DO_DIR}" "${SERVICE_LOOK_DIR}" -type f -print0 | xargs -0 sed -i \
	-e "s|%service_group_here%|${SERVICE_GROUP//|/\\|}|g" \
	-e "s|%service_name_here%|${SERVICE_NAME//|/\\|}|g" \
	-e "s|%command_here%|${COMMAND//|\\|}|g" \
	-e "s|%down_cmd_here%|${DOWN_COMMAND//|/\\|}|g"

find "${SERVICE_DO_DIR}" "${SERVICE_LOOK_DIR}" -type f -print0 | xargs -0 sed -i \
	-e "s|__NEWLINE__|$'\n'|g"

for service in "$@"; do
	case "${SRV_TYPE}" in
		bundle) touch "${SERVICE_DO_DIR}/contents.d/${service}" ;;
		oneshot|longrun) touch "${SERVICE_DO_DIR}/dependencies.d/${service}" ;;
	esac
done

find "${SERVICE_DO_DIR}" "${SERVICE_LOOK_DIR}" \
	-name 'run' -or \
	-name 'finish' -or \
	-name 'up' -or \
	-name 'down' \
	-print0 | xargs -0 -I{} chmod +x {}

printf '%s\n' "$(fmt_ok "Service '${SERVICE_NAME}' created successfully.")"

