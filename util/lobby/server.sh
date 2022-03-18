#!/usr/bin/env bash
[[ -f env.sh ]] && . env.sh

while read -p "Server: " -er line; do
	history -s "$line"
	if [[ $line == "~" ]]; then
		./lobby.sh
		./get-hosts.sh > hosts-full.csv
		continue
	fi

	printf '\nProcessing the following matches:\n'
	grep -i "$line" hosts-full.csv
	printf "\n"
	./watch.sh <(grep -i "$line" hosts-full.csv)
done
