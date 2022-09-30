

python /net/rijn/data2/rvweeren/LoTSS_ClusterCAL/facetselfcal.py --imsize=1600 -i
 selfcal_allstations3_LBCS --pixelscale=0.075 --uvmin=20000 --robust=-1.5 --uvminim=1500 --skymodel=7C1604+5529.skymodel --soltype-list="['scalarphasediff','scalarphase','scalarphase','scalarphase','scalarcomplexgain','fulljones']" --soltypecycles-list="[0,0,0,0,0,0]" --solint-list="['8min','32s','32s','2min','20min','20mi
n']" --nchan-list="[1,1,1,1,1]" --smoothnessconstraint-list="[10.0,1.25,10.0,20.,7.5,5.0]" --normamps=False --smoothnessreffrequency-list="[120.,120.,120.,120,0.,
0.]" --antennaconstraint-list="['alldutch',None,None,None,None,'alldutch']" --forwidefield --avgfreqstep=5 --a
vgtimestep=4 --skipbackup --docircular --uvminscalarphasediff=0 --makeimage-ILTlo
wres-HBA --makeimage-fullpol --resetsols-list="[None,'alldutch','core',None,None,
None]" --stop=2 L816272_120_168MHz_averaged.ms