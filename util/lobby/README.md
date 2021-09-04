POSIX shell scripts to fetch and parse lobby data.

The scripts optionally accept specific regions as arguments, defaulting to all. Namely: china, eu, sing, us


`fetch.sh` - Outputs human-readable lobby data into *region*.json.
`chars.sh` - Parses *region*.json and outputs a ranking of how many people are using a character.


To run `fetch.sh`, you'll need to set the `KLEI_TOKEN` environmental variable to your client token. The simplest way to retrieve this is to run `print(THeFrontEnd:GetAccountManager():GetToken()` in the in-game console.

Note that this token expires, so you'll have to get new ones periodically. Alternatively, you can ask Klei for a permanent token; they are open to it and have given them to several sites that utilize lobby data.
