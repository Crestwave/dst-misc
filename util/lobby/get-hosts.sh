#!/bin/sh
cd ./listings || exit

gunzip -fk -- *.gz
awk -F \" '
	BEGIN { RS = "," }
	/"host"/ { printf("%s", $4) }
	/"name"/ { printf(",%s,%s\n", $4, FILENAME) }
	' -- *.json
