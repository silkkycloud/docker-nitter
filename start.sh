#!/usr/bin/env bash

set -euo pipefail

if [ "${GEN_HMAC:-n}}" = "y" ] ; then
  hmac=$(openssl rand -base64 32)
  sed -i "s/secretkey/$hmac/g" nitter.conf
fi

echo "Giving Redis time to start"
sleep 2s

exec ./nitter
