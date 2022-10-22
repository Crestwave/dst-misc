#!/usr/bin/env bash
while getopts bc opt; do
	case $opt in
		b) b=1 ;;
		c) c=1 ;;
	esac
done

shift $(( OPTIND - 1 ))

[[ -z $c ]] && ./server.sh '~'

awk '
	/[[:digit:]]+-[[:digit:]]+$/ {
		split($NF, r, "-")
		$NF = ""
		for (i = r[1]; i <= r[2]; ++i)
			print $0 i
		next
	}
	
	{ print }
	' "${1:-serverlist}" >grouplist

latest=$(./version.sh ${b:+"-b"})

while read -r line; do
	if [[ -n $b && $line == *Beta* ]] || [[ -z $b && $line != *Beta* ]]; then
		sv=$(grep ",\(\[󰀘\] \)\?$line," hosts-full.csv)
		if [[ -n $sv ]]; then
			IFS=, read -r host name region version group <<<"$sv"
			if [[ $version != $latest ]]; then
				printf '%s %s\n' "$line" OUTDATED
			fi
		else
			printf '%s %s\n' "$line" DOWN
		fi
	fi
done <grouplist
