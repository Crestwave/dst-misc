#!/bin/sh
[ "$#" -eq 0 ] && set china eu sing us

for i; do
	set "$@" data/"$1".json
	shift
done

awk -F '\\\\"' '
	BEGIN { RS = "\\\\n" }
	/prefab=/ { a[$2] += 1 }
	END { for (i in a) print a[i] " - " i }
	' "$@" | sort -n
