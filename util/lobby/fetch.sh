#!/bin/sh
[ "$#" -eq 0 ] && set ap-east-1 ap-southeast-1 eu-central-1 us-east-1

cd ./listings || exit
gunzip -fk *.gz
cd - >/dev/null || exit

printf "parallel\n" >data/curlrc

for region; do
	mkdir -p data/"$region"
	rm -f data/"$region"/*.json

	printf 'Processing %s lobby data...\n' "$region"

	awk -F\" -v RS=, '/"__rowId"/ { print $4 }' listings/"$region"*.json |
		while read -r row; do
			printf 'next
data = {"__gameId":"DontStarveTogether","__token":"%s","query":{"__rowId":"%s"}}
url = https://lobby-v2-%s.klei.com/lobby/read
output = data/%s/%s.json
' "$KLEI_TOKEN" "$row" "$region" "$region" "$row"
		done >>data/curlrc
done

curl -K data/curlrc
