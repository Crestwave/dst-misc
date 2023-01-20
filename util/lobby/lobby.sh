#!/bin/sh
mkdir -p listings
cd ./listings || exit
printf '%s\n' parallel remote-name-all >curlrc

url=https://lobby-v2-cdn.klei.com

if [ "$#" -gt 0 ]; then
	for i; do
		printf 'Downloading %s...\n' "$url"/"$i".json.gz
		printf 'url = "%s"\n' "$url"/"$i".json.gz >>curlrc
	done
else
	set Steam PSN Rail XBone Switch
	curl "$url"/regioncapabilities-v2.json |
		jq -r '.LobbyRegions[][]' |
			while read -r region; do
				for i; do
					printf 'url = "%s"\n' "$url/$region-$i.json.gz" >>curlrc
				done
			done
fi

curl -K curlrc
