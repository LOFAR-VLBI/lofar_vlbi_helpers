#!/bin/bash
#SBATCH -c 2 --job-name=phaseshift --array=1-1000%100

export SIMG=/project/lofarvwf/Software/singularity/lofar_sksp_v3.4_x86-64_generic_noavx512_ddf.sif

LNUM=$1

echo "Job landed on $(hostname)"

pattern="${LNUM}*.parset"
files=( $pattern )
N=${SLURM_ARRAY_TASK_ID}

singularity exec -B $PWD,/project,/home/lofarvwf-jdejong/scripts $SIMG DP3 ${files[${N}]}
echo "Launched script for ${files[${N}]}"
