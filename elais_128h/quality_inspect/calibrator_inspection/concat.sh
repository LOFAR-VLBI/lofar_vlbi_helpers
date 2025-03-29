#!/bin/bash

LNUM=$1

for j in 0 1 2; do
 for i in 0 1 2 3 4 5 6 7 8 9; do
  DP3 msin=*${LNUM}*SB${j}${i}*.MS msout=${LNUM}.ms.tmp${j}${i} steps=[filter,avg] filter.type=filter filter.baseline="^[CR]S*&&" filter.remove=true avg.freqstep=8 avg.timestep=8 msout.storagemanager='dysco'
 done
done

DP3 msin=${LNUM}.ms.tmp?? msout=${LNUM}.ms steps=[] msout.storagemanager='dysco'

rm -rf *.ms.tmp??
