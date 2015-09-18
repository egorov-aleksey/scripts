#!/bin/bash

HG=/usr/bin/hg

DAYS=30

get_expired_branches(){
  $HG log -r "head() and not closed() and not date('-$DAYS') and not branch('default')" --template="\"{branch}\"\n"
}

get_expired_branches_for_user(){
  $HG log -r "sort(head() and not closed() and not date('-$DAYS') and not branch('default'), user)" --template="{author}\t{branch}\t{date|isodate}\n"
}

yesno(){
    echo
    echo -n "$1 [Y/n] "

    read answer

    case "$answer" in
	n|N) echo "Exit"
	    exit 0
	    ;;
    esac

}

changes="$($HG status)"

errcode="$?"

if [ $errcode -ne 0 ]; then
    echo "Exit with error code $errcode"
    exit $errcode
fi

if [ -n "$changes" ]; then
    echo "Found uncommitted changes:"
    echo
    $HG status

    yesno "Uncommitted changes will be discarded! Would you like to continue?"
fi

echo
echo "Pulling new changesets..."
$HG pull > /dev/null

echo
echo "List of expired branches (not active over $DAYS days):"

exp_branches="$(get_expired_branches_for_user)"

if [ -z "$exp_branches" ]; then
    echo "Empty ;)"
    echo "Nothing to do. Exit."
    exit 0
else
    echo
    get_expired_branches_for_user | nl

    yesno "Would you like to continue to close all these branches?"
fi

current_branch="$($HG branch)"

for br in $(get_expired_branches); do
    echo "Switch branch on $br"
    $HG up -C "$br" > /dev/null

    if [ $? -eq 0 ]; then
      echo "Closing of branch $br"
      $HG commit --close-branch -m "Close branch (not active over $DAYS days)" > /dev/null
    fi
done

echo
echo "Done."

echo
echo "Swith to current branch ($current_branch)"
$HG up -C "$current_branch" > /dev/null


yesno "Would you like to continue to push to remote repository?"

echo
echo "Pushing to remote repository..."
$HG push > /dev/null

exit 0
