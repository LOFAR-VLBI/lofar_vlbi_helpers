#!/bin/bash

SOLUTIONS=$1

DP3 \
msin=L816272_115MHz_P50892.ms \
msout=L816272_115MHz_P50892_circ.ms \
msin.datacolumn=DATA \
msout.storagemanager=dysco \
msout.writefullresflag=False \
steps=[beam,ac,avg,pystep] \
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
pystep.python.module=polconv \
pystep.python.class=PolConv \
pystep.type=PythonDPPP \
pystep.lin2circ=1
