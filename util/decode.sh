#!/bin/sh
awk '{
	if (/KLEI/) {
		sub(/1D/, "")
		print $2
	} else {
		print $0
	}
}'  "$1" | base64 -d | dd ibs=16 skip=1 2>/dev/null | openssl zlib -d
