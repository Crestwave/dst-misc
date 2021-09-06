The process for this set of scripts can be separated into two sections:

### Setup

1. Parse https://s3.amazonaws.com/klei-lobby for the complete list of lobby listings.
2. Download new copies of any listings that are out of date.
3. Select a server to watch. We define a server as its name, its hoster, and the listing it is in.
4. Save this definition in a file to be parsed later.

### Watching

1. Extract the server's rowId from the listings using our definitions.
2. If the rowId is invalid, redownload a copy of the listing it is specifically in.
3. Query Klei's lobby for the server's full data using its rowId.
4. Process the data for your needs.

## Sample workflow

```sh
$ export KLEI_TOKEN=pcl-usc^[REDACTED]
$ ./lobby.sh
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 21017    0 21017    0     0   5072      0 --:--:--  0:00:04 --:--:--  5072
China-PSN-lavaarena.json.gz: OK
China-PSN-noevent.json.gz: OK
China-PSN-quagmire.json.gz: OK
China-Rail-lavaarena.json.gz: OK
China-Rail-noevent.json.gz: FAILED
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  339k  100  339k    0     0  60168      0  0:00:05  0:00:05 --:--:-- 76561
[TRUNCATED]
$ ./get-hosts.sh | grep 'Klei Official' | sed '/PS4/d' >klei.csv
$ # with the initial setup complete, we can now just call watch.sh repeatedly
$ ./watch.sh klei.csv
Fetching sing lobby data for 7c5513234eb6cb7a56f857e2e6713a77...
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  4285    0  4101  100   184   5867    263 --:--:-- --:--:-- --:--:--  6130
Catcoon Den - Klei Official: Day 49 - 7 days left in spring

[Crestwave] - willow - 765611[REDACTED]
[REDACTED] - wortox - 765611[REDACTED]
[REDACTED] - wilson - 765611[REDACTED]
[REDACTED] - winona - 765611[REDACTED]
[REDACTED] - wortox - 765611[REDACTED]
[REDACTED] - wes - 765611[REDACTED]
[REDACTED] - wendy - 765611[REDACTED]
[REDACTED] - wurt - 765611[REDACTED]
[TRUNCATED]
$ # later...
$ ./watch.sh klei.csv 2>&1 | grep day
Catcoon Den - Klei Official: Day 15 - 6 days left in autumn
Catch that Splumonkey - Klei Official: Day 73 - 18 days left in autumn
Ipsguiggle was here! - Klei Official: Day 25 - 11 days left in winter
Spiders and Such - Klei Official: Day 92 - 14 days left in winter
Hound Huggles - Klei Official: Day 109 - 17 days left in spring
```
