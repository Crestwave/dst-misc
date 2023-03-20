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
			./fetch-row.sh "${name%-*}" "$id"

			read -r data <row/"$id".json

			case $data in
				'{"Error":{"Code":"E_NOT_IN_DB"}}')
					printf 'rowId invalid; updating %s\n' \
						"$3".gz >&2
					./lobby.sh "${3%.json}"
					gunzip -fk listings/"$3".gz
					[ "$4" != 1 ] && get_server "$@" 1
					exit
					;;
				'{"Error":'*)
					err="${data#'{"Error":'}"
					err="${err%'}'}"
					printf 'Received error %s\n' "$err" >&2

					continue
					;;
				'<html>'*)
					while read -r err; do
						case $err in *'<title>'*)
							err="${err##*'<title>'}"
							err="${err%%'</title>'*}"
							printf 'Received response: %s\n' "$err" >&2
						esac
					done <row/"$id".json

					continue
					;;
			esac

			./row-info.sh row/"$id".json
			printf "\n"
		done
}

while IFS=, read -r host name file _; do
	get_server "$host" "$name" "$file"
done <"${1:-hosts.csv}"
