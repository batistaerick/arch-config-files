#!/usr/bin/env bash

CITY="Sao%20Jose%20dos%20Pinhais"

weather=$(curl -sf "https://wttr.in/${CITY}?format=%t")

if [ -z "$weather" ]; then
  echo "N/A"
else
  echo "$weather"
fi
