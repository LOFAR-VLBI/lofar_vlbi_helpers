#!/bin/bash

for F in facet_*; do
  echo "$F"
  echo "Number of MS: $(ls -1d $F/imaging/*.ms | wc -l)"
  echo "Size $(du -sh $F/imaging)"
  echo ""
done