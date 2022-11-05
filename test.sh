#!/bin/bash

file="list.txt"

while read -r WORD; do
  if [[ "$WORD" =~ ^(L3123|dog|horse)$ ]]; then
      echo "$WORD is in the list"
  else
      echo "$WORD is not in the list"
  fi
done <$file