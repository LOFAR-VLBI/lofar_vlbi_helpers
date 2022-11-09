#!/bin/bash
#SBATCH -N 1 -c 2 --job-name=phaseshift
#SBATCH --array 1-2500%200

export SIMG=/project/lofarvwf/Software/singularity/lofar_sksp_v3.4_x86-64_generic_noavx512_ddf.sif

echo "Job landed on $(hostname)"

PATH_MS=/project/lofarvwf/Share/jdejong/output/ELAIS/${OBSERVATION}/subtract/subtract_lotss
SCRIPTS=/home/lofarvwf-jdejong/scripts/prefactor_helpers

pattern="${LNUM}*.parset"
files=( $pattern )
N=${SLURM_ARRAY_TASK_ID}

singularity exec -B $PWD,/project,/home/lofarvwf-jdejong/scripts $SIMG DP3 ${files[${N}]}
echo "Launched script for ${files[${N}]}"