#!/usr/bin/env bash
while read -r line; do
	printf '\nProcessing the following matches:\n'
	grep -i "$line" hosts-full.csv
	printf "\n"
	./watch.sh <(grep -i "$line" hosts-full.csv)
done
