#!/usr/bin/env bash
./server.sh '~'
awk '
	/[[:digit:]]+-[[:digit:]]+$/ {
		split($NF, r, "-")
		$NF = ""
		for (i = r[1]; i <= r[2]; ++i)
			print $0 i
		next
	}
	
	{ print }
	' serverlist >grouplist

latest=$(curl -s https://s3.amazonaws.com/dstbuilds/builds.json | jq '.release[-1] | tonumber')

while read -r line; do
	[[ $line == *Beta* ]] && continue
	sv=$(grep ",\(\[󰀘\] \)\?$line," hosts-full.csv || echo "$line" DOWN >&2)
	if [[ $sv ]]; then
		IFS=, read -r host name region version group <<<"$sv"
		if [[ $version != $latest ]]; then
			echo "$line" OUTDATED
		fi
	fi
done <grouplist
