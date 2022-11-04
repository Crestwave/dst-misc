#!/bin/sh
getopts b opt

if [ "$opt" = b ]; then
	curl -s https://s3.amazonaws.com/dstbuilds/builds.json | jq '.updatebeta[-1] | tonumber'
else
	curl -s https://s3.amazonaws.com/dstbuilds/builds.json | jq '.release[-1] | tonumber'
fi
