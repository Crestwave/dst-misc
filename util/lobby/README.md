POSIX shell scripts to fetch and parse lobby data.

The scripts optionally accept specific regions as arguments, defaulting to all. Namely: ap-east-1, ap-southeast, eu-central-1, us-east-1


* `fetch.sh` - Outputs lobby data into data/*region*/\*.json.
* `chars.sh` - Parses data/*region*/\*.json and outputs a ranking of how many people are using a character.


To run `fetch.sh`, you'll need to set the `KLEI_TOKEN` environmental variable your cluster token. The simplest way to retrieve this is to run `print(TheNet:GenerateClusterToken())` in the in-game console.

Note: Because of the lobby v2 update, you will now need to run `lobby.sh` before `fetch.sh`.

---

The next set of scripts is a bit hairier due to an overabundance of ad-hoc parsing.

The overall goal of this set is to periodically query data from specific servers. Thus, its raison d'être is to reduce downloading as much as is practical—`fetch.sh` cannot be used as it downloads the entire region's complete dataset at once.

* `lobby.sh` - Fetches all lobby *listings*.
* `get-hosts.sh` - Parses lobby listings into a CSV format for `watch.sh`.
* `fetch-row.sh` - `fetch.sh`, but queries for a specific server (*region* *row*).
* `row-info.sh` - Extracts some basic info about a row.
* `watch.sh` - Parses `get-hosts.sh` output to invoke `fetch-row.sh` and `row-info.sh`.
* `version.sh` - Fetches the latest server version; requires `jq` (*-b* for beta).
* `server.sh` - Bash script for easily searching servers.
* `status.sh` - Bash script for easily checking the status of a list of servers (*-b* for beta, *-c* for cached data).
* `status2.sh` - Similar to `status.sh`, but queries the list of servers from Google Sheets.

For more information, see [watch.md](watch.md).
