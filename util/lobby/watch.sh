#!/bin/sh
get_server() {
	host=$1 name=$2 awk -F \" '
		BEGIN { RS = "," }
		/"__rowId"/ { id = $4 }
		/"host"/ { host=($4 == ENVIRON["host"])  }
		/"name"/ {
			if (host && $4 == ENVIRON["name"]) {
				printf("%s,%s\n", id, tolower(FILENAME))
				exit
			}
		}
		' listings/"$3" | while IFS=, read -r id name; do
			name="${name##*/}"
			./fetch-row.sh "${name%%-*}" "$id"

			if ! awk '{ if ($0 == "{\"GET\":[]}") exit 1 }' \
				row/"$id".json
			then
				printf 'rowId invalid; redownloading %s\n' \
					"$3".gz
				./lobby.sh "${3%.json}"
				gunzip -fk listings/"$3".gz
				[ "$4" != 1 ] && get_server "$@" 1
				exit
			fi

			./row-info.sh row/"$id".json
		done
}

while IFS=, read -r host name file _; do
	get_server "$host" "$name" "$file"
done <"${1:-hosts.csv}"
