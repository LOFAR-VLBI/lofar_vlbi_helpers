#!/bin/bash
#SBATCH -c 120 -J LINTar -p normal,infinite

#INPUT
LNUM=$(realpath $1)
CAL_SOLUTIONS=$(realpath $2)

SCRIPT_DIR=/home/lofarvwf-jdejong/scripts/lofar_vlbi_helpers/edfn
OUTDIR=$PWD

RUNDIR=$(realpath ${TMPDIR}/LINCrun)
mkdir -p ${RUNDIR}
cd ${RUNDIR}

source $SCRIPT_DIR/setup.sh --no-git --no-sing

ulimit -S -n 8192

# Ensure < 168 MHz
singularity exec $SIMG_CACHE_DIR/${SIMG}.sif \
python ~/scripts/lofar_vlbi_helpers/elais_200h/download_scripts/removebands.py \
--freqcut 168 --datafolder ${LNUM}

source ${VENV}/bin/activate
flocs-run linc target \
--slurm-time "4:00:00" \
--runner cwltool \
--scheduler singleMachine \
--solveralgorithm directioniterative \
--cal-solutions ${CAL_SOLUTIONS} \
--output-fullres-data \
${LNUM}
deactivate

echo "COPYING ${RUNDIR} to ${OUTDIR}"
rsync -a ${RUNDIR} ${OUTDIR}
echo "FINISHED"
