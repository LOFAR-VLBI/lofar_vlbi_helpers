#!/bin/bash

SOLUTIONS=$1

DP3 \
msin=L816272_115MHz_P50892.ms \
msout=L816272_115MHz_P50892_lin.ms \
msin.datacolumn=DATA \
msout.storagemanager=dysco \
msout.writefullresflag=False \
steps=[beam,ac,avg] \
avg.type=averager \
avg.freqresolution=390.56kHz \
avg.timeresolution=60 \
beam.type=applybeam \
beam.updateweights=True \
beam.direction=[] \
beam.usechannelfreq=True \
ac.type=applycal \
ac.parmdb=${SOLUTIONS} \
ac.correction=fulljones \
ac.soltab=[amplitude000,phase000]
