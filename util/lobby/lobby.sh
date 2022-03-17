#!/bin/sh
mkdir -p listings
cd ./listings || exit
printf '%s\n' parallel remote-name-all >curlrc

url=https://s3.amazonaws.com/klei-lobby

if [ "$#" -gt 0 ]; then
	for i; do
		printf 'Downloading %s...\n' "$url"/"$i".json.gz
		curl "$url"/"$i".json.gz -o "$i".json.gz
	done
else
	curl "$url" |
		awk '
			BEGIN { RS = "(<Contents>|</Contents>)" }
			/<Key>/ {
				gsub(/<[^/]*>/, "")
				gsub(/<\/[^>]*>/, ",")
				gsub("&quot;", "")
				print
			}
			' |
				while IFS=, read -r file _ md5 _; do
					if ! printf '%s  %s\n' "$md5" "$file" |
						md5sum -c 2>/dev/null
					then
						printf 'url = "%s"\n' \
							"$url/$file" >>curlrc
					fi
				done
fi

curl -K curlrc
