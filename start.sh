#!/usr/bin/env bash

set -euo pipefail

hmac=$(openssl rand -base64 32)
sed -i "s@secretkey@$hmac@g" /nitter/nitter.conf

echo "Giving Redis time to start"
sleep 2s

exec ./nitter
