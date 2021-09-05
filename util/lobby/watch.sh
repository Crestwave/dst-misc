#!/bin/sh
while IFS=, read -r host name file; do
	host=$host name=$name awk -F \" '
		BEGIN { RS = "," }
		/"__rowId"/ { id = $4 }
		/"host"/ { host=($4 == ENVIRON["host"])  }
		/"name"/ {
			if (host && $4 == ENVIRON["name"]) {
				printf("%s,%s\n", id, tolower(FILENAME))
				exit
			}
		}
		' "$file" | while IFS=, read -r id name; do
			./fetch-row.sh "${name%%-*}" "$id"

			if ! awk '{ if ($0 == "{\"GET\":[]}") exit 1 }' \
				"$id".json
			then
				printf 'rowId invalid; redownloading %s\n' \
				       	"$file".gz
				./lobby.sh "${file%.json}"
				gunzip -fk "$file".gz
				"$0" "${1:-hosts.csv}"
				exit
			fi

			./row-info.sh row/"$id".json
		done
done <"${1:-hosts.csv}"
