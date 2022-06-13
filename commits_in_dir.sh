#!/usr/bin/env bash
#   vim: set tabstop=4 modeline modelines=10:
#   vim: set foldlevel=2 foldcolumn=2 foldmethod=marker:
#	{{{2
nl=$'\n'
tab=$'\t'
#set -o errexit   # abort on nonzero exitstatus
set -o nounset   # abort on unbound variable
set -o pipefail  # don't hide errors within pipes
#	Ongoing: 2022-06-14T06:40:20AEST need a reliable way to filter out not-ours repos

flag_debug=1
log_debug() {
	#	{{{
	if [[ $flag_debug -ne 0 ]]; then
		echo "$@" > /dev/stderr
	fi
}
#	}}}

delim=$'\t'

commits_in_dir() {
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
	local func_about="about"
	local func_help="""$func_name, $func_about
	\$1					path_dir (default \$PWD)
	-T | --top 			do not descend into repos
	-v | --debug
	-h | --help"""
	#	{{{
	if echo "${1:-}" | perl -wne '/^\s*-h|--help\s*$/ or exit 1'; then
		echo "$func_help"
		return 2
	fi
	#	}}}
	#	parse args "$@"
	#	{{{
	for arg in "$@"; do
		case $arg in
			-T|--top)
				flag_top_only=1
				shift
				;;
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
	#	{{{
	if [[ ! -d "$path_dir" ]]; then
		echo "$func_name, error, dir not found, path_dir=($path_dir)" > /dev/stderr
		exit 2
	fi
	#	}}}

	local repos_in_dir=""
	if [[ $flag_top_only -ne 0 ]]; then
		#	Ongoing: 2022-06-14T06:06:19AEST as taken from 'find_repos_in_dir' '-T|--top' option is problematic (excludes top level dir, inconsistent with/without trailing '/' on path, <>)
		repos_in_dir=$( find "$path_dir/" \( -exec test -d '{}'/.svn \; -or -exec test -d {}/.git \; -or -exec test -d {}/CVS \; \) -print -prune )
	else
		repos_in_dir=$( find "$path_dir" -type d -name .git 2> /dev/null | xargs -I {} dirname {} )
	fi

	local IFS=$nl
	local combined_history_epochPathHash=$( combined_repo_historyAsEpochPathHash "$repos_in_dir" | sort )

	report_combined_history "$combined_history_epochPathHash"

}

report_combined_history() {
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
	local combined_history_epochPathHash="$1"
	#	validate non-empty: combined_history_epochPathHash
	#	{{{
	if [[ -z "$combined_history_epochPathHash" ]]; then
		echo "$func_name, error, empty combined_history_epochPathHash=($combined_history_epochPathHash)" > /dev/stderr
		exit 2
	fi
	#	}}}
	local IFS=$nl
	local combined_history_epochs=( $( echo "$combined_history_epochPathHash"  | cut -d"$delim" -f1 ) )
	local combined_history_paths=( $( echo "$combined_history_epochPathHash"  | cut -d"$delim" -f2 ) )
	local combined_history_hashes=( $( echo "$combined_history_epochPathHash"  | cut -d"$delim" -f3 ) )
	#	validation: array length sanity check
	#	{{{
	if [[ ${#combined_history_epochs[@]} -ne ${#combined_history_paths[@]} ]] || [[ ${#combined_history_paths[@]} -ne ${#combined_history_hashes[@]} ]]; then
		echo "$func_name, error, len mismatch (sanity check, please investigate)" > /dev/stderr
		exit 2
	fi
	#	}}}
	local i=0
	while [[ $i -lt ${#combined_history_epochs[@]} ]]; do
		log_debug "$func_name, i=($i)" 
		local loop_epoch=${combined_history_epochs[@]:$i:1}
		local loop_path=${combined_history_paths[@]:$i:1}
		local loop_hash=${combined_history_hashes[@]:$i:1}
		log_debug "$func_name, loop_epoch=($loop_epoch)"
		log_debug "$func_name, loop_path=($loop_path)"
		log_debug "$func_name, loop_hash=($loop_hash)"
		i=$(( $i + 1 ))
	done
	#local IFS=$nl
	#local combined_history_epochPathHash=( $( echo "$@" ) )
	#for loop_epochPathHash in "${combined_history_epochPathHash[@]}"; do
	#	#local loop_epoch=$( echo "$loop_epochPathHash" | cut -d"$delim" -f1 )
	#	#local loop_path=$( echo "$loop_epochPathHash" | cut -d"$delim" -f2 )
	#	#local loop_hash=$( echo "$loop_epochPathHash" | cut -d"$delim" -f3 )
	#	#local loop_epoch=$( echo "$loop_epochPathHash" | awk '{ print $1 }' )
	#	#local loop_path=$( echo "$loop_epochPathHash" | awk '{ print $2 }' )
	#	#local loop_hash=$( echo "$loop_epochPathHash" | awk '{ print $3 }' )
	#	#log_debug "$func_name, loop_epoch=($loop_epoch)"
	#	#log_debug "$func_name, loop_path=($loop_path)"
	#	#log_debug "$func_name loop_hash=($loop_hash)"
	#done
}

combined_repo_historyAsEpochPathHash() {
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
	local IFS=$nl
	local repos_in_dir=( $( echo "$@" ) )

	for loop_repo in "${repos_in_dir[@]}"; do
		log_debug "$func_name, loop_repo=($loop_repo)"
		local loop_history=$( repo_historyAsEpochPathHash "$loop_repo" )
		log_debug "$func_name, lines(loop_history)=(`echo "$loop_history" | wc -l`)"
		#log_debug "$func_name, loop_history=($loop_history)"
		echo "$loop_history"
	done
}

repo_historyAsEpochPathHash() {
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
	local path_str="$1"
	#	{{{
	if [[ ! -d "$path_dir" ]]; then
		echo "$func_name, error, dir not found, path_dir=($path_dir)" > /dev/stderr
		exit 2
	fi
	#	}}}
	local temp_PWD=$PWD
	cd "$path_str"
	#TZ=UTC0 git log --date=iso --pretty=format:"%ad$delim$path_str$delim%H"
	git log --date=unix --pretty=format:"%ad$delim$path_str$delim%H"
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
	commits_in_dir "$@"
fi


