#!/bin/bash
#SBATCH -c 2 --job-name=split_batch3 --array=0-999%100 --constraint=amd

export SIMG=/project/lofarvwf/Software/singularity/lofar_sksp_v4.0.2_znver2_znver2_noavx512_ddf_10_02_2023.sif

LNUM=$1

echo "Job landed on $(hostname)"

pattern="${LNUM}*.parset"
files=( $pattern )
N=$(( ${SLURM_ARRAY_TASK_ID}+2000 ))

singularity exec -B $PWD,/project,/home/lofarvwf-jdejong/scripts $SIMG DP3 ${files[${N}]}
echo "Launched script for ${files[${N}]}"
