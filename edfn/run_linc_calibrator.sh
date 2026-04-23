#!/bin/bash
#SBATCH -N 1 -c 32 -t 24:00:00 -J LINCal -p normal,infinite

OUTDIR=$PWD
DATA=$PWD/data

RUNDIR=$(realpath ${TMPDIR}/LINCrun)
mkdir -p ${RUNDIR}
cd ${RUNDIR}

SCRIPT_DIR=/home/lofarvwf-jdejong/scripts/lofar_vlbi_helpers/edfn

source $SCRIPT_DIR/setup.sh --no-git --no-sing

ulimit -S -n 8192

singularity exec $SIMG_CACHE_DIR/${SIMG}.sif \
python ~/scripts/lofar_vlbi_helpers/elais_200h/download_scripts/removebands.py \
--freqcut 168 --datafolder $DATA

# Run LINC calibrator
source ${VENV}/bin/activate
flocs-run linc calibrator \
--runner cwltool \
--solveralgorithm directioniterative \
$DATA
deactivate

echo "COPYING $RUNDIR to $OUTDIR"
cp -r $RUNDIR $OUTDIR
echo "FINISHED"
