#!/bin/sh
[ "$#" -eq 0 ] && set china eu sing us

read -r data <<EOF
{"__gameId":"DontStarveTogether","__token":"$KLEI_TOKEN","query":{}}
EOF

mkdir -p data
for i; do
	url=https://lobby-$i.klei.com/lobby/read

	printf 'Fetching %s lobby data...\n' "$i"
	curl -w '\n' -d "$data" "$url" >data/"$i".json
done
