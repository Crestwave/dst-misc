#!/bin/sh
getopts b opt

if [ "$opt" = b ]; then
	curl -s 'https://forums.kleientertainment.com/game-updates/dst/' |
		awk -F '[-/]' '
			/class=.cRelease./ && !/data-currentRelease/ {
				print $7
				exit
			}'
else
	curl -s https://s3.amazonaws.com/dstbuilds/builds.json | jq '.release[-1] | tonumber'
fi
