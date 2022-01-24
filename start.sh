#!/usr/bin/env bash

if [[ -v $HMAC_KEY ]]; then
  echo "No hmac key!"
  exit 1;
else
  sed -i "s@secretkey@$HMAC_KEY@g" /nitter/nitter.conf
fi

sleep 2s

exec ./nitter
