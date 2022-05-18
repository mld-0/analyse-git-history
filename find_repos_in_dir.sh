#!/usr/bin/env sh
#   VIM SETTINGS: {{{3
#   vim: set tabstop=4 modeline modelines=10 foldmethod=marker:
#   vim: set foldlevel=2 foldcolumn=2:
#   }}}1
set -o errexit   # abort on nonzero exitstatus
set -o nounset   # abort on unbound variable
set -o pipefail  # don't hide errors within pipes
#	{{{2

#	Continue: 2022-05-18T15:34:07AEST does command used 'git log' (with formatting/before/after arguments) get every commit (recalling subdirectory repo merged as a branch (and '-m' being needed?) (see worklog))?
#	Ongoing: 2022-05-18T16:54:15AEST functions should be legible / elegent with only func_name/arg-parsing bash stuff collapsed
#	Ongoing: 2022-05-18T16:54:59AEST (this script / another script), (lines changed for each commit)
#	Ongoing: 2022-05-18T16:56:38AEST commits per day, for (more than one repo) (all repos in subdirectories)

#	Allow subshell 'exit 2' to terminate script
set -E;
trap '[ "$?" -ne 2 ] || exit 2' ERR


path_testdir="$HOME"


_validate_find_repos_dir() {
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
	\$1					path_dir
	-h | --help"""
	#	{{{
	if echo "${1:-}" | perl -wne '/^\s*-h|--help\s*$/ or exit 1'; then
		echo "$func_help"
		return 2
	fi
	#	}}}
	local path_dir="${1:-}"
	if [[ -d "$path_dir" ]]; then
		echo "$func_name, error, dir not found, path_dir=($path_dir)" > /dev/stderr
		exit 2
	fi
}

_validate_is_repo_toplevel() {
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
	\$1					path_repo
	-h | --help"""
	#	{{{
	if echo "${1:-}" | perl -wne '/^\s*-h|--help\s*$/ or exit 1'; then
		echo "$func_help"
		return 2
	fi
	#	}}}
	local path_repo="${1:-}"
	#	Continue: 2022-05-18T22:22:51AEST is 'path_repo' the top level of a git repo <(treatment of nested repos?)>
	echo "UNIMPLEMENTED" > /dev/stderr
	exit 2
}

_filter_repo() {
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
	local func_about="Determine whether a given repo should be excluded from output"
	local func_help="""$func_name, $func_about
	\$1					path_repo
	-h | --help"""
	#	{{{
	if echo "${1:-}" | perl -wne '/^\s*-h|--help\s*$/ or exit 1'; then
		echo "$func_help"
		return 2
	fi
	#	}}}
	local path_repo="${1:-}"
	#	Continue: 2022-05-18T22:22:03AEST logic to decide which repos to exclude
	if [[ ! -z "$path_repo" ]]; then
		echo "true"
	else
		echo "false"
	fi
}

find_repos_in_dir() {
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
	local func_about="Find all git repos in directory (recursive)"
	local func_help="""$func_name, $func_about
	\$1					path_dir (default \$PWD)
	-h | --help"""
	#	{{{
	if echo "${1:-}" | perl -wne '/^\s*-h|--help\s*$/ or exit 1'; then
		echo "$func_help"
		return 2
	fi
	#	}}}
	local path_dir="${1:-$PWD}"
	_validate_find_repos_dir "$path_dir"

	#	Continue: 2022-05-18T22:24:51AEST find repos in 'path_dir' recursively
	#	LINK: https://stackoverflow.com/questions/11981716/how-to-quickly-find-all-git-repos-under-a-directory

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
	echo "" > /dev/null
fi

