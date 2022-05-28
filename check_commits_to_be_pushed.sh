#!/usr/bin/env bash
#   vim: set tabstop=4 modeline modelines=10:
#   vim: set foldlevel=2 foldcolumn=2 foldmethod=marker:
#	{{{2
set -o errexit   # abort on nonzero exitstatus
set -o nounset   # abort on unbound variable
set -o pipefail  # don't hide errors within pipes

flag_debug=0

log_debug() {
#	{{{
	if [[ $flag_debug -ne 0 ]]; then
		echo "$@" > /dev/stderr
	fi
}
#	}}}

check_commits_to_be_pushed() {
	#	{{{
	local func_name=""
	if [[ -n "${ZSH_VERSION:-}" ]]; then 
		func_name=${funcstack[1]:-}
	elif [[ -n "${BASH_VERSION:-}" ]]; then
		func_name="${FUNCNAME[0]:-}"
	else
		printf "%s\n" "warning, func_name unset, non zsh/bash shell" > /dev/stderr
	fi
	#	}}}
	local func_about="about"
	local func_help="""$func_name, $func_about
	\$1					path_dir, default=(PWD)
	-v | --debug
	-h | --help"""
	#	{{{
	if echo "${1:-}" | perl -wne '/^\s*-h|--help\s*$/ or exit 1'; then
		echo "$func_help"
		return 2
	fi
	#	}}}
	#	{{{
	for arg in "$@"; do
		case $arg in
			-h|--help)
				echo "$func_help"
				return 2
				shift
				;;
			-v|--debug)
				flag_debug=1
				shift
				;;
		esac
	done
	#	}}}
	local path_dir="${1:-$PWD}"
	local temp_PWD="$PWD"
	cd "$path_dir"

	if [[ ! -z `has_remote_origin "$path_dir"` ]]; then
		result_str=$( git diff --stat --cached origin/$( git branch --show-current ) )
		echo "$result_str"
	else
		log_debug "$func_name, has not has_remote_origin, path_dir=($path_dir)" 
	fi

	cd "$temp_PWD"
}

has_remote_origin() {
	local path_dir="$1"
	local temp_PWD=$PWD
	cd "$path_dir"
	if [[ ! -z `git remote -v` ]]; then
		echo "true"
	fi
	cd "$temp_PWD"
}

check_sourced=1
#	{{{
if [[ -n "${ZSH_VERSION:-}" ]]; then 
	if [[ ! -n ${(M)zsh_eval_context:#file} ]]; then
		check_sourced=0
	fi
elif [[ -n "${BASH_VERSION:-}" ]]; then
	(return 0 2>/dev/null) && check_sourced=1 || check_sourced=0
else
	echo "error, check_sourced, non-zsh/bash" > /dev/stderr
	exit 2
fi
#	}}}
if [[ "$check_sourced" -eq 0 ]]; then
	check_commits_to_be_pushed "$@"
fi

