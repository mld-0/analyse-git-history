#!/usr/bin/env bash
#   vim: set tabstop=4 modeline modelines=10:
#   vim: set foldlevel=2 foldcolumn=2 foldmethod=marker:
#	{{{2
nl=$'\n'
tab=$'\t'
set -o errexit   # abort on nonzero exitstatus
set -o nounset   # abort on unbound variable
set -o pipefail  # don't hide errors within pipes

flag_debug=1
log_debug() {
	#	{{{
	if [[ $flag_debug -ne 0 ]]; then
		echo "$@" > /dev/stderr
	fi
}
#	}}}

path_find_repos="find_repos_in_dir.sh"
path_check_commitsToPush="check_commits_to_be_pushed.sh"
#	validate existance: path_find_repos, path_check_commitsToPush
#	{{{
if [[ ! -f "$path_find_repos" ]]; then
	echo "error, not found, path_find_repos=($path_find_repos" > /dev/stderr
	exit 2
fi
if [[ ! -f "$path_check_commitsToPush" ]]; then
	echo "error, not found, path_check_commitsToPush=($path_check_commitsToPush)" > /dev/stderr
	exit 2
fi
#	}}}


search_repos_pending_push() {
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
	\$1				path_dir, default=(\$PWD)
	-v | --debug
	-h | --help"""
	#	{{{
	if echo "${1:-}" | perl -wne '/^\s*-h|--help\s*$/ or exit 1'; then
		echo "$func_help"
		return 2
	fi
	#	}}}
	#	process args "$@"
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
	log_debug "$func_name, path_dir=($path_dir)"

	IFS_temp=$IFS
	IFS=$nl
	local repos_in_dir=( $( $SHELL "$path_find_repos" "$path_dir" ) )
	IFS=$IFS_temp

	repos_result=""
	delim=$nl
	for loop_repo in "${repos_in_dir[@]}"; do
		log_debug "$func_name, loop_repo=($loop_repo)"
		if [[ -z `$SHELL "$path_check_commitsToPush" "$loop_repo"` ]]; then
			repos_result="$repos_result$delim$loop_repo"
		fi
	done

	echo "$repos_result"
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
	search_repos_pending_push "$@"
fi

