#!/bin/sh
read -r data <<EOF
{"__gameId":"DontStarveTogether","__token":"$KLEI_TOKEN","query":{"__rowId":"$2"}}
EOF

mkdir -p row

url=https://lobby-$1.klei.com/lobby/read
printf 'Fetching %s lobby data for %s...\n' "$1" "$2"
curl -w '\n' -d "$data" "$url" >row/"$2".json
