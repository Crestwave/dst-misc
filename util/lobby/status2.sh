#!/usr/bin/env bash
while getopts bc opt; do
	case $opt in
		b) b=1 ;;
		c) c=1 ;;
	esac
done

shift $(( OPTIND - 1 ))

[[ -f env.sh ]] && . env.sh

if [[ -z $c ]]; then
	./server.sh '~'
	curl "$DST_SHEETS_URL" |
		jq -r '.values | sort_by(.[2])[] | @csv' |
		awk '{
			if (/[[:digit:]]+-[[:digit:]]+"/) {
				match($0, /[[:digit:]]+-[[:digit:]]+"/)
				split(substr($0, RSTART, RLENGTH-1), r, "-")
				for (i = r[1]; i <= r[2]; ++i)
					print substr($0, 1, RSTART-1) i "\"" substr($0, RSTART+RLENGTH)
			} else {
				print
			}
		}' >servers.csv
fi

latest=$(./version.sh ${b:+"-b"})

while IFS=',"' read -r _ server _ _ region _ _ host _; do
	if [[ -n $b && $server == *Beta* ]] || [[ -z $b && $server != *Beta* ]]; then
		sv=$(grep ",\(\[󰀘\] \)\?$server," hosts-full.csv | sort -r)
		if [[ -n $sv ]]; then
			IFS=, read -r _host _name _region _version _group <<<"$sv"
			if [[ $_version != $latest ]] && [[ -z $KLEI_STEAMCLANID || $KLEI_STEAMCLANID == $_group ]]; then
				printf '%s: %s - %s\n' "$host" "$server" OUTDATED
			fi
		else
			printf '%s: %s - %s\n' "$host" "$server" DOWN
		fi
	fi
done <servers.csv
