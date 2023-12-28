#!/bin/sh
set -eu
HERE="$(dirname "$(realpath "$0")")"
. "${HERE}"/paths.sh
. "${BIN}"/fmt.sh

usage() {
    printf 'Usage: %s\n' "$0 <group>:<name_of_service> <commands to run...> [-- dependencies...] [-- down_command...]"
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

# parsing up command
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


# copying mock templates
case "${SRV_TYPE}" in
	longrun|bundle)
		SERVICE_DO_DIR="${S6_SERVICE_HOME}/${SERVICE_GROUP}/${SERVICE_NAME}-do" 
		SERVICE_LOOK_DIR="${S6_SERVICE_HOME}/${SERVICE_GROUP}/${SERVICE_NAME}-look" 
		cp -rT "${HERE}/mock/${SRV_TYPE}/do" "${SERVICE_DO_DIR}"
		cp -rT "${HERE}/mock/${SRV_TYPE}/look" "${SERVICE_LOOK_DIR}"
		;;
	oneshot)
		SERVICE_DO_DIR="${S6_SERVICE_HOME}/${SERVICE_GROUP}/${SERVICE_NAME}" 
		cp -rT "${HERE}/mock/${SRV_TYPE}/do" "${SERVICE_DO_DIR}"
		;;
esac

# adding dependencies
for service in "$@"; do
	case "${SRV_TYPE}" in
		bundle) touch "${SERVICE_DO_DIR}/contents.d/${service}" ;;
		oneshot) touch "${SERVICE_DO_DIR}/dependencies.d/${service}" ;;
		longrun) touch "${SERVICE_DO_DIR}/dependencies.d/${service}" ;;
		--) break ;;
	esac
	shift
done

# parsing down command
DOWN_COMMAND=''
NEWLINE=''
for arg in "$@"; do
	shift;
	if test "${arg}" = '--'; then break; fi
	DOWN_COMMAND="${DOWN_COMMAND}${NEWLINE}${arg}"
	NEWLINE=$'\n'
done

replace_placeholders() {
	NEWLINE=$'\n'

	up_cmd="${COMMAND//${NEWLINE}/__NEWLINE__}"
	down_cmd="${DOWN_COMMAND//${NEWLINE}/__NEWLINE__}"
	find "${@}" -type f -print0 | xargs -0 sed -i \
		-e "s|%service_group_here%|${SERVICE_GROUP//|/\\|}|g" \
		-e "s|%service_name_here%|${SERVICE_NAME//|/\\|}|g" \
		-e "s|%command_here%|${up_cmd//|\\|}|g" \
		-e "s|%down_cmd_here%|${down_cmd//|/\\|}|g"

	find "${@}" -type f -print0 | xargs -0 sed -i \
		-e "s|__NEWLINE__|\n|g"
}

make_executable() {
	find "${@}" \
		-name 'run' -or \
		-name 'finish' -or \
		-name 'up' -or \
		-name 'down' \
		-print0 | xargs -0 -I{} chmod +x {}
}

# slapping on commands

case "${SRV_TYPE}" in
	oneshot)
		replace_placeholders "${SERVICE_DO_DIR}"
		make_executable "${SERVICE_DO_DIR}"
		;;
	longrun|bundle)
		replace_placeholders "${SERVICE_DO_DIR}" "${SERVICE_LOOK_DIR}"
		make_executable "${SERVICE_DO_DIR}" "${SERVICE_LOOK_DIR}"
		;;
esac

printf '%s\n' "$(fmt_ok "Service '${SERVICE_NAME}' created successfully.")"

