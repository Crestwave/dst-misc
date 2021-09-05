#!/bin/sh
url=https://s3.amazonaws.com/klei-lobby

if [ "$#" -gt 0 ]; then
	for i; do
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
			' | while read -r line; do
					IFS=,
					set -f
					set +f $line
					unset IFS
					
					if ! printf '%s  %s\n' "$3" "$1" |
						md5sum -c 2>/dev/null
					then
						curl "$url"/"$1" -o "$1"
					fi
				done
fi
