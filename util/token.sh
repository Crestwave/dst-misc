#!/bin/sh
token=${1:-"$(cat cluster_token.txt)"}
curl -d '{"Token":"'"$token"'","Game":"DontStarveTogether"}' https://login.kleientertainment.com/login/TokenPurpose
