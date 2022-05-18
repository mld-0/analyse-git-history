#!/usr/bin/env sh
#   VIM SETTINGS: {{{3
#   vim: set tabstop=4 modeline modelines=10 foldmethod=marker:
#   vim: set foldlevel=2 foldcolumn=2:
#   }}}1
set -o errexit   # abort on nonzero exitstatus
set -o nounset   # abort on unbound variable
set -o pipefail  # don't hide errors within pipes
#	{{{2
#	Ongoings:
#	{{{
#	Ongoing: 2022-05-18T21:04:34AEST implementing 'count_commits_by_day' in terms of commits_by_day output -> (how might that compare with speed of current function?)
#	Ongoing: 2022-05-18T16:42:50AEST a way to produce the same output as 'commits_by_day(path, -d)', with (far fewer commands) (a faster, smarter way) <(this is an inelegant disaster (compared to what was envisioned))>
#	Ongoing: 2022-05-18T16:40:34AEST (we started out with such good intentions) (to observe 'best practices for functions' when creating this script) (but (the realities of bash (poor excuse) and) having a problem to solve results in (see above))
#	Ongoing: 2022-05-18T16:39:18AEST 'count_commits_by_day' should be (easily) implementable by summing results of commits_by_day -> (and that implies there is substantial duplication between them)
#	Ongoing: 2022-05-18T16:54:15AEST functions should be legible / elegent with only func_name/arg-parsing bash stuff collapsed
#	Ongoing: 2022-05-18T16:54:59AEST (this script / another script), (lines changed for each commit)
#	Ongoing: 2022-05-18T16:56:38AEST commits per day, for (more than one repo) (all repos in subdirectories)
#	Ongoing: 2022-05-18T22:48:48AEST (slow) (for any kind of repo with a moderate history) -> (profile what is taking so long)
#	Ongoing: 2022-05-18T15:25:22AEST 'get_commits_on_date()' before/after are inclusive of specified times (and therefore would specifying times without seconds get commits made in the first/last seconds of the day?)
#	}}}
#	Continue: 2022-05-18T15:34:07AEST does command used 'git log' (with formatting/before/after arguments) get every commit (recalling subdirectory repo merged as a branch (and '-m' being needed?) (see worklog))?
#	Continue: 2022-05-18T22:59:55AEST 'print_commits_for_date()' use of perl one-liners is considerably slower than grep/sed alternatives? (and it especially matters here, in a function called in a loop) [...] (or, rather, it is git log (specifically with before/after date filters) that is slow?)

#	Allow subshell 'exit 2' to terminate script
set -E;
trap '[ "$?" -ne 2 ] || exit 2' ERR

path_testdir="$HOME/Dropbox/_sandpit/effective-c++"
allow_non_toplevel=1
count_commits_sum_days=0

#	UNIMPLEMENTED:
get_all_days_between_dates() {
#	{{{
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
	local func_about="Get all unique days between two dates"
	local func_help="""$func_name, $func_about
		UNIMPLEMENTED
		\$1		date_start
		\$2		date_end
	"""
	#	{{{
	if echo "${1:-}" | perl -wne '/^\s*-h|--help\s*$/ or exit 1'; then
		echo "$func_help"
		return 2
	fi
	#	}}}
	local date_start="${1:-}"
	local date_end="${2:-}"
	echo "UNIMPLEMENTED" > /dev/stderr
	exit 2
}
#	}}}
#	UNUSED:
get_first_last_commit_dates() {
#	{{{
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
	local func_about="Get dates of first/last commit"
	local func_help="""$func_name, $func_about
		\$1		path_dir
	"""
	#	{{{
	if echo "${1:-}" | perl -wne '/^\s*-h|--help\s*$/ or exit 1'; then
		echo "$func_help"
		return 2
	fi
	#	}}}
	local result=$( get_unique_commit_dates "$path_dir" | perl -ne 'print if ($. == 1 or eof); ' ) 
	echo "$result"
}
#	}}}
#	DUPLICATION SUSPECT/CASE-STUDY: 
count_commits_by_day() {
#	{{{
#	{{{
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
	local func_about="Number of commits for each date corresponding to 'get_unique_commit_dates' output"
	local func_help="""$func_name, $func_about
		\$1		path_dir
		-d | --dates		include leading column with dates
	"""
	#	{{{
	if echo "${1:-}" | perl -wne '/^\s*-h|--help\s*$/ or exit 1'; then
		echo "$func_help"
		return 2
	fi
	#	}}}
	local path_dir="${1:-}"
	if [[ -z "$path_dir" ]]; then
		echo "$func_name, \$1 = path_dir not given, use PWD=($PWD)" > /dev/stderr
		path_dir="$PWD"
	else
		shift
	fi
	local flag_output_dates=0
	local delim_date=$'\t'

	for arg in "$@"; do
	#	{{{
		case $arg in
			-h|--help)
				echo "$func_help"
				return 2
				shift
				;;
			-d|--dates)
				flag_output_dates=1
				shift
				;;
		esac
	done
	#	}}}

	_validate_path_git_repo "$path_dir"

	local temp_PWD="$PWD"
	cd "$path_dir"
	local counts=$( git log --date=short --pretty=format:%ad | sort | uniq -c | perl -lane 'print $F[0]' )
	if [[ -z "$counts" ]]; then
		echo "$func_name, error, no commits" > /dev/stderr
		exit 2
	fi
	if [[ $flag_output_dates -eq 0 ]]; then
		echo "$counts"
	else
		#echo "$counts"
		local unique_dates_commits=( $( get_unique_commit_dates "$path_dir" ) )
		local counts_list=( $( echo "$counts" ) )

		#	Ongoing: 2022-05-18T15:57:37AEST assuming array elements do not contain newlines (see below) (paste can be used)
		#	LINK: https://stackoverflow.com/questions/32998146/bash-printf-two-arrays-in-two-columns
		paste <(printf "%s\n" "${unique_dates_commits[@]}") <(printf "%s\n" "${counts_list[@]}")

	fi
	cd "$temp_PWD"
}
#	}}}
#	}}}


get_unique_commit_dates() {
#	{{{
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
	local func_about="sorted list of unique dates of commits"
	local func_help="""$func_name, $func_about
		\$1		path_dir
	"""
	#	{{{
	if echo "${1:-}" | perl -wne '/^\s*-h|--help\s*$/ or exit 1'; then
		echo "$func_help"
		return 2
	fi
	#	}}}
	local path_dir="${1:-}";
	local temp_PWD="$PWD"
	cd "$path_dir"
	local result=$( git log --date=short --pretty=format:%ad | sort | uniq )
	echo "$result"
	cd "$temp_PWD"
}
#	}}}


is_dir_git_repo() {
#	{{{
	#	func_help: (z,sh)
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
	local func_about="Is this directory a git repo? (echo 'true' / 'false')"
	local func_help="""$func_name, $func_about
		\$1		path_dir
	"""
	#	{{{
	if echo "${1:-}" | perl -wne '/^\s*-h|--help\s*$/ or exit 1'; then
		echo "$func_help"
		return 2
	fi
	#	}}}
	local path_dir="${1:-}";
	local temp_PWD=$PWD
	cd "$path_dir"
	local result=$( git rev-parse --is-inside-work-tree )
	echo "$result"
	cd "$temp_PWD"
}
#	}}}

is_top_level_git_repo() {
#	{{{
	#	func_help: (z,sh)
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
	local func_about=""
	local func_help="""$func_name, $func_about
		\$1		path_dir
	"""
	#	{{{
	if echo "${1:-}" | perl -wne '/^\s*-h|--help\s*$/ or exit 1'; then
		echo "$func_help"
		return 2
	fi
	#	}}}
	local path_dir="${1:-}"
	if [[ $( is_dir_git_repo "$path_dir" ) == "false" ]]; then
		echo "false"
		return
	fi
	local temp_PWD=$PWD
	cd "$path_dir"
	if [[ $( realpath $( git rev-parse --show-toplevel ) ) == $( realpath "$path_dir" ) ]]; then
		echo "true"
	else
		echo "false"
	fi
	cd "$temp_PWD"
}
#	}}}


_validate_path_git_repo() {
#	{{{
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
	local func_about="Ensure directory has a valid git repo for the purpouses of (top level script functions)"
	local func_help="""$func_name, $func_about
		\$1		path_dir
	"""
	#	{{{
	if echo "${1:-}" | perl -wne '/^\s*-h|--help\s*$/ or exit 1'; then
		echo "$func_help"
		return 2
	fi
	#	}}}
	local path_dir="${1:-}"
	if [[ ! -d "$path_dir" ]]; then
		echo "$func_name, error, not a dir, path_dir=($path_dir)" > /dev/stderr
		exit 2
	fi
	if [[ ! $( is_dir_git_repo "$path_dir" ) == "true" ]]; then
		echo "$func_name, error, not a git repo, path_dir=($path_dir)" > /dev/stderr
		exit 2
	fi
	if [[ $allow_non_toplevel -eq 0 ]] && [[ ! $( is_top_level_git_repo "$path_dir" ) == "true" ]]; then
		echo "$func_name, error, not top level of git repo, path_dir=($path_dir)" > /dev/stderr
		exit 2
	fi
}
#	}}}


_validate_date_str() {
#	{{{
	local date_str="${1:-}"
	if echo "$date_str" | perl -wne '/^\d{4}-\d{2}-\d{2}$/ and exit 1'; then
		echo "$func_name, error, invalid date_str=($date_str)" > /dev/stderr
		exit 2;
	fi
}
#	}}}


count_commits_total() {
#	{{{
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
	local func_about="total number of commits in directory"
	local func_help="""$func_name, $func_about
		\$1		path_dir
	"""
	#	{{{
	if echo "${1:-}" | perl -wne '/^\s*-h|--help\s*$/ or exit 1'; then
		echo "$func_help"
		return 2
	fi
	#	}}}
	local path_dir="${1:-}"
	#_validate_path_git_repo "$path_dir"
	temp_PWD=$PWD
	cd "$path_dir"
	local all_commits=( $( git log --date=short --pretty=format:%ad ) )
	echo "${#all_commits[@]}"
	cd "$temp_PWD"
}
#	}}}


get_commits_on_date() {
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
	local func_about="Get all commits (as hashes) made on a certain date"
	local func_help="""$func_name, $func_about
		\$1		path_dir
		\$2		date_str
	"""
	#	{{{
	if echo "${1:-}" | perl -wne '/^\s*-h|--help\s*$/ or exit 1'; then
		echo "$func_help"
		return 2
	fi
	#	}}}
	local path_dir="${1:-}"
	local date_str="${2:-}"

	#	Ongoing: 2022-05-18T15:17:22AEST (slow) (for 'effective-c++', validating date makes ~0.2s difference)
	_validate_date_str "$date_str"

	local temp_PWD=$PWD
	cd "$path_dir"
	local result=$( git log --after="$date_str 00:00:00" --before="$date_str 23:59:59" --format="%H" )
	echo "$result"
	cd "$temp_PWD"
}


_validate_unique_dates_len() {
#	{{{
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
	local func_about="Is number of unique_dates > 0?"
	local func_help="""$func_name, $func_about
		\$1		unique_dates_len"""
	#	{{{
	if echo "${1:-}" | perl -wne '/^\s*-h|--help\s*$/ or exit 1'; then
		echo "$func_help"
		return 2
	fi
	#	}}}
	local unique_dates_commits_len="${1:-0}"
	if [[ "$unique_dates_commits_len" -eq 0 ]]; then
		echo "$func_name, error, no commits" > /dev/stderr
		exit 2
	fi
}
#	}}}


_validate_counts_sum_verification() {
#	{{{
	local count_commits_verification=$( count_commits_total "$path_dir" )
	if [[ $count_commits_verification -le 0 ]]; then
		echo "$func_name, error, 0 > count_commits_verification=($count_commits_verification)" > /dev/stderr
		exit 2
	fi
	if [[ $count_commits_sum_days -ne $count_commits_verification ]]; then
		echo "$func_name, error, count_commits_sum_days=($count_commits_sum_days) != count_commits_verification=($count_commits_verification)" > /dev/stderr
		exit 2
	fi
}
#	}}}


print_commits_for_date() {
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
	local func_about=""
	local func_help="""$func_name, $func_about
	-h | --help"""
	#	{{{
	if echo "${1:-}" | perl -wne '/^\s*-h|--help\s*$/ or exit 1'; then
		echo "$func_help"
		return 2
	fi
	#	}}}
	local path_dir="${1:-$PWD}"
	local date_str="${2:-}"
	local flag_output_dates="${3:-}"

	local delim_commits=","
	local delim_date=$'\t'

	local commit_hashes=$( get_commits_on_date "$path_dir" "$loop_date" | perl -pe "s/\n/$delim_commits/g" | perl -pe "s/$delim_commits\$//" )

	if [[ $flag_output_dates -ne 0 ]]; then
		printf "%s$delim_date" "$loop_date";
	fi
	echo "$commit_hashes"

	local commit_hashes_len=$( echo "$commit_hashes" |  perl -pe "s/$delim_commits/\n/g" | wc -l )
	count_commits_sum_days=$(( $count_commits_sum_days + $commit_hashes_len ))
}


commits_by_day() {
	#	func_help: (z,sh)
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
	local func_about=""
	local func_help="""$func_name, $func_about
		\$1					path_dir
		-D | --nodates		exclude leading column of dates
		-h | --help"""
	#	{{{
	if echo "${1:-}" | perl -wne '/^\s*-h|--help\s*$/ or exit 1'; then
		echo "$func_help"
		return 2
	fi
	#	}}}
	local path_dir="${1:-$PWD}"
	_validate_path_git_repo "$path_dir"
	local flag_output_dates=1
	#	{{{
	for arg in "$@"; do
		case $arg in
			-h|--help)
				echo "$func_help"
				return 2
				shift
				;;
			-D|--nodates)
				flag_output_dates=0
				shift
				;;
		esac
	done
	#	}}}

	local unique_dates_commits=( $( get_unique_commit_dates "$path_dir" ) )
	_validate_unique_dates_len "${#unique_dates_commits[@]}"

	#	Ongoing: 2022-05-18T22:55:00AEST most of the runtime is in loop below:
	count_commits_sum_days=0
	for loop_date in "${unique_dates_commits[@]}"; do
		print_commits_for_date "$path_dir" "$loop_date" "$flag_output_dates"
	done
	_validate_counts_sum_verification 
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
	commits_by_day "$@"
	#	{{{
	#count_commits_by_day "$@"
	#commits_by_day "$path_testdir" -d
	#count_commits_by_day "$path_testdir" -d
	#get_unique_commit_dates "$path_testdir"
	#count_commits_by_day "$path_testdir"
	#commits_by_day "$path_testdir"
	#	}}}
fi

