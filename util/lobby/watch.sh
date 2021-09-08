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

			read -r data <row/"$id".json

			case $data in
				'{"error":'*)
					err="${data#'{"error":'}"
					err="${err%'}'}"
					printf 'Received error %s\n' "$err" >&2

					continue
					;;
				'{"GET":[]}')
					printf 'rowId invalid; updating %s\n' \
						"$3".gz >&2
					./lobby.sh "${3%.json}"
					gunzip -fk listings/"$3".gz
					[ "$4" != 1 ] && get_server "$@" 1
					exit
					;;
			esac

			./row-info.sh row/"$id".json
		done
}

while IFS=, read -r host name file _; do
	get_server "$host" "$name" "$file"
done <"${1:-hosts.csv}"
