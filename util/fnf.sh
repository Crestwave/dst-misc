#!/bin/sh
token=$(cat cluster_token.txt)
curl -d '{"Token":"'"$token"'","KU":"'"$1"'","Game":"DontStarveTogether"}' https://login.kleientertainment.com/login/FamilySharingLookup
