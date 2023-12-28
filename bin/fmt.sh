#!/bin/sh

fmt_ok() {
	colour="$(tput setaf 2)"
	reset="$(tput sgr0)"
	printf "%s%s%s" "${colour}" "$@" "${reset}"
}
fmt_info() {
	colour="$(tput setaf 4)"
	reset="$(tput sgr0)"
	printf "%s%s%s" "${colour}" "$@" "${reset}"
}
fmt_debug() {
	colour="$(tput setaf 8)"
	reset="$(tput sgr0)"
	printf "%s%s%s" "${colour}" "$@" "${reset}"
}
fmt_err() {
	colour="$(tput setaf 1)"
	reset="$(tput sgr0)"
	printf "%s%s%s" "${colour}" "$@" "${reset}"
}
fmt_warn() {
	colour="$(tput setaf 3)"
	reset="$(tput sgr0)"
	printf "%s%s%s" "${colour}" "$@" "${reset}"
}

