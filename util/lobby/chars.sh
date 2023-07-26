#!/bin/sh
[ "$#" -eq 0 ] && set ap-east-1 ap-southeast-1 eu-central-1 us-east-1

for _; do
	set "$@" data/"$1"/*.json
	shift
done

awk -F '\\\\"' '
	BEGIN { RS = "\\\\n" }
	/prefab=/ { a[$2] += 1 }
	END { for (i in a) print a[i] " - " i }
	' "$@" | sort -n
