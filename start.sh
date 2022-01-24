#!/usr/bin/env bash

if [[ -v $HMAC_KEY ]]; then
  sed -i "s@secretkey@$HMAC_KEY@g" /nitter/nitter.conf
else
  echo "No hmac key!"
  exit 1;
fi

sleep 2s

exec ./nitter
