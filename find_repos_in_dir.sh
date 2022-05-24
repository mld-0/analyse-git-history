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
flag_debug=0

log_debug() {
#	{{{
	if [[ $flag_debug -ne 0 ]]; then
		echo "$@" > /dev/stderr
	fi
}
#	}}}

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
	local flag_top_only=0
	local func_about="Find all git repos in directory (recursive)"
	local func_help="""$func_name, $func_about
	\$1					path_dir (default \$PWD)
	-T | --top			do not descend into repos
	-h | --help"""
	#	{{{
	if echo "${1:-}" | perl -wne '/^\s*-h|--help\s*$/ or exit 1'; then
		echo "$func_help"
		return 2
	fi
	#	}}}
	local path_dir="${1:-$PWD}"
	if [[ ! -d "$path_dir" ]]; then
		echo "$func_name, error, dir not found, path_dir=($path_dir)" > /dev/stderr
		exit 2
	fi
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
			-T|--top)
				flag_top_only=1
				shift
				;;
		esac
	done
	#	}}}


	path_dir=$( realpath "$path_dir" )
	log_debug "$func_name, path_dir=($path_dir)"
	_validate_find_repos_dir "$path_dir"

	#	Continue: 2022-05-18T22:24:51AEST find repos in 'path_dir' recursively
	#	LINK: https://stackoverflow.com/questions/11981716/how-to-quickly-find-all-git-repos-under-a-directory
	#	LINK: https://unix.stackexchange.com/questions/333862/how-to-find-all-git-repositories-within-given-folders-fast

	if [[ $flag_top_only -ne 0 ]]; then
		#	{{{
		#	Solution if pruning below .git is enough
		#find "$path_dir" -type d -path '*/.git' -print -prune | xargs -I {} dirname {} 2> /dev/null
		#find "$path_dir" -type d -path '*/.git' -printf '%h\n' -prune 2> /dev/null
		#	Solution if the whole folder tree should be pruned once a .git is found
		#for d in $path_dir; do
		#	  find "$d" -type d -name .git -print -quit
		#done | xargs -I {} dirname {}
		#	}}}
		find "$path_dir/" \( -exec test -d '{}'/.svn \; -or \
		   -exec test -d {}/.git \; -or -exec test -d {}/CVS \; \) \
		   -print -prune
	else
		#	Solution not pruning below .git
		find "$path_dir" -type d -name .git 2> /dev/null | xargs -I {} dirname {}
	fi

}

_validate_find_repos_dir() {
	local path_dir="${1:-}"
	if [[ ! -d "$path_dir" ]]; then
		echo "$func_name, error, dir not found, path_dir=($path_dir)" > /dev/stderr
		exit 2
	fi
}


_filter_repo() {
	local path_repo="${1:-}"
	#	Continue: 2022-05-18T22:22:03AEST logic to decide which repos to exclude
	if [[ ! -z "$path_repo" ]]; then
		echo "true"
	else
		echo "false"
	fi
}

#_validate_is_repo_toplevel() {
#	local path_repo="${1:-}"
#	#	Continue: 2022-05-18T22:22:51AEST is 'path_repo' the top level of a git repo <(treatment of nested repos?)>
#	echo "UNIMPLEMENTED" > /dev/stderr
#	exit 2
#}

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
	find_repos_in_dir "$@"
fi

