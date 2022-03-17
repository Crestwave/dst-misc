#!/bin/sh
awk -F \" '
	BEGIN  {
		connections = 0
		RS = ","
	}
	/"name"/ { name = $4 }
	/"season"/ { season = $4 }
	/"maxconnections"/ {
		sub(/:/, "")
		maxconnections = $3
	}
	/day=/ {
		sub(/.*=/, "")
		day = $0
	}
	/daysleftinseason=/ {
		sub(/.*=/, "")
		sub(/ .*/, "")
		days = $0
	}
	/netid=/ { connections += 1 }
	END {
		printf("%s (%s/%s): Day %s - %s days left in %s\n\n",
			name, connections, maxconnections, day, days, season)
	}
	' "$1"
awk -F '\\\\"' '
	BEGIN { RS = "\\\\n" }
	/name=/ { name = $2 }
	/netid=/ { netid = $2 }
	/prefab=/ { printf("%s - %s - %s\n", name, $2, netid) }
	' "$1"
