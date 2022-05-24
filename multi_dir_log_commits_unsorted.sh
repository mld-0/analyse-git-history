#	Get logs of multiple repos (but the commits are not in order)
#	LINK: https://stackoverflow.com/questions/50882822/view-logs-of-multiple-git-repositories
CODE_BASE=(
~/Dropbox/_src
~/Dropbox/_mld
~/Dropbox/_sandpit
)
EXCLUDE_PATT="gitRepoYouWantToIgnore" #this is regex

for base in ${CODE_BASE[@]};do
    echo "##########################"
    echo "   scanning $base"
    echo "##########################"
    for line in $(find "$base" -name ".git"|grep -v "$EXCLUDE_PATT"); do
        line=$(sed 's#/\.git##'<<<"$line")
        repo=$(awk -F'/' '$0=$NF' <<<"$line")
        echo "##########################"
        echo "====> Showing log of Repository: $repo <===="
        echo "##########################"
        git -C "$line" log --date=relative
    done
done
