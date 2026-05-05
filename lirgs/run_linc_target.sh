#!/bin/bash
#SBATCH -c 64 -t 72:00:00 -J LINTar -p normal,infinite

OUTDIR=$PWD
DATA=$PWD/data
CAL_SOLUTIONS=$(abspath $1)

RUNDIR=$(realpath ${TMPDIR}/LINCrun)
mkdir -p ${RUNDIR}
cd ${RUNDIR}

SCRIPT_DIR=/home/lofarvwf-jdejong/scripts/lofar_vlbi_helpers/edfn

source $SCRIPT_DIR/setup.sh --no-git --no-sing

ulimit -S -n 8192

# Ensure < 168 MHz
singularity exec $SIMG_CACHE_DIR/${SIMG}.sif \
python ~/scripts/lofar_vlbi_helpers/elais_200h/download_scripts/removebands.py \
--freqcut 168 --datafolder ${DATA}

source ${VENV}/bin/activate
flocs-run linc target \
--runner cwltool \
--solveralgorithm directioniterative \
--cal-solutions ${CAL_SOLUTIONS} \
${DATA}
deactivate

echo "COPYING ${RUNDIR} to ${OUTDIR}"
rsync -a ${RUNDIR} ${OUTDIR}
echo "FINISHED"
