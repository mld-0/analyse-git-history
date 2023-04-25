#!/usr/bin/env sh
#	{{{3
#   vim: set tabstop=4 modeline modelines=10:
#   vim: set foldlevel=2 foldcolumn=2 foldmethod=marker:
#	{{{2
#	Notes:
#	{{{
#	2023-04-25T21:59:19AEST include private repos?
#	2023-04-25T22:02:25AEST github's API rate limit is paltry (for 'unverified' <accounts/requests>)
#	}}}

set -o errexit   # abort on nonzero exitstatus
set -o nounset   # abort on unbound variable
set -o pipefail  # don't hide errors within pipes
nl=$'\n'

log_debug() {
	echo "$@" > /dev/stderr
}


#	For accounts with <= 100 repositories
get_account_repo_links_list() {
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
	account="mld-0"

	#	get all repos for accounts with <= 100
	#	Ongoing: 2023-04-25T22:06:41AEST make 'authenticated' api request, check for 'rate limit exceeded' in 'response'
	local response=`curl -s "https://api.github.com/users/$account/repos?per_page=100"`
	#log_debug "$func_name, response=($response)"
	local IFS_temp=$IFS
	local IFS=$'\n'
	local repos=( `echo "$response" | grep -o 'git@[^"]*'` )
	IFS=$IFS_temp
	if [[ "${#repos[@]}" -le 0 ]]; then
		echo "$func_name, error, no repos found for account=($account)" > /dev/stderr
		exit 2
	fi
	#log_debug "$func_name, repos=(${repos[@]})"

	#	getting all repos for accounts with > 100 (INCOMPLETE)
	#	{{{
	#repos_count=$(curl -s "https://api.github.com/users/${account}" | grep -o '"public_repos": *[0-9]*' | grep -o '[0-9]*')
	#repos=""
	#PAGE=1
	#while [ `perl -E "say ($PAGE-1)*100"` -lt $repos_count ]; do
	#	log_debug "$func_name, PAGE=($PAGE)"
	#	 loop_repos=`curl -s "https://api.github.com/users/${account}/repos?page=${PAGE}&per_page=100" | grep -o 'git@[^"]*'`
	#	 repos="$loop_repos$nl$repos"
	#	PAGE=`perl -E "say $PAGE + 1"`
	#done
	#local IFS_temp=$IFS
	#local IFS=$nl
	#repos=( `echo "$repos"` )
	#IFS=$IFS_temp
	#	}}}

	for repo in "${repos[@]}"; do
		echo "$repo"
		#	we can now clone each one and peform commands in it
	done
}

get_account_repo_links_list "$@"

