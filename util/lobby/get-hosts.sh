#!/bin/sh
gunzip -fkl *.gz
awk -F \" '
	BEGIN { RS = "," }
	/"host"/ { printf("%s", $4) }
	/"name"/ { printf(",%s,%s\n", $4, FILENAME) }
	' *.json
