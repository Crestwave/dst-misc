#!/bin/sh
cd ./listings || exit

gunzip -fk -- *.gz

if [ "$1" = "-s" ]; then
	awk -F \" -- '
		BEGIN { RS = "," }
		/"host"/ { printf("%s,", $4) }
		/"name"/ { printf("%s,%s\n", $4, FILENAME) }
		' *.json
else
	awk -F \" -- '
		BEGIN { RS = "," }
		/"host"/ { printf("%s,", $4) }
		/"name"/ { printf("%s,", $4) }
		/"steamclanid"/ { steamclanid = $4 }
		/"v"/ {
			gsub(/[:}\]]/, "", $3)
			if (steamclanid)
				printf("%s,%s,%s\n", FILENAME, $3, steamclanid)
			else
				printf("%s,%s\n", FILENAME, $3)

			steamclanid = 0
		}
		' *.json
fi
