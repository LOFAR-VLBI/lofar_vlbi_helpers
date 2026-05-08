#!/bin/bash
#SBATCH -c 24 -p infinite,normal -t 48:00:00

######################
#### UPDATE THESE ####
######################

FACET_NUMBER=$1
CONFIG=$2
MSIN=$3

######################
######################

RUNDIR=$TMPDIR/selfcal
OUTDIR=$PWD/selfcal_facet_${FACET_NUMBER}

mkdir -p ${RUNDIR}
mkdir -p ${OUTDIR}

cp -r ${MSIN}/*.ms ${RUNDIR}
cp ${CONFIG} ${RUNDIR}

cd ${RUNDIR}

wget https://public.spider.surfsara.nl/project/lofarvwf/fsweijen/containers/flocs_v6.0.0_znver2_znver2.sif

singularity exec -B $PWD flocs_v6.0.0_znver2_znver2.sif \
facetselfcal --configpath $(basename ${CONFIG}) *.ms

cp merged*.h5 ${OUTDIR}
cp plotlosoto* ${OUTDIR}
cp *.fits ${OUTDIR}
cp *.png ${OUTDIR}
