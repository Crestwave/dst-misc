#!/bin/sh
awk -F \" '
	BEGIN  { RS = "," }
	/"name"/ { name = $4 }
	/"season"/ { season = $4 }
	/day=/ {
		sub(/.*=/, "")
		day = $0
	}
	/daysleftinseason=/ {
		sub(/.*=/, "")
		sub(/ .*/, "")
		days = $0
	}
	END {
		printf("%s: Day %s - %s days left in %s\n\n",
			name, day, days, season)
	}
	' "$1"
awk -F '\\\\"' '
	BEGIN { RS = "\\\\n" }
	/name=/ { name = $2 }
	/netid=/ { netid = $2 }
	/prefab=/ { printf("%s - %s - %s\n", name, $2, netid) }
	' "$1"
