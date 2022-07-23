#!/usr/bin/env bash
HISTCONTROL=ignoreboth:erasedups
HISTFILE=$PWD/.server_history
HISTFILESIZE=10

[[ -f env.sh ]] && . env.sh
(( $# )) && exec <<<"$*"
history -r

while read -p "Server: " -er line; do
	history -s "$line"
	if [[ $line == "~" ]]; then
		./lobby.sh
		./get-hosts.sh >hosts-full.csv
		continue
	fi

	printf '\nProcessing the following matches:\n'
	grep -i -- "$line" hosts-full.csv
	printf "\n"
	./watch.sh <(grep -i -- "$line" hosts-full.csv)
done

history -w
