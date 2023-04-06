#!/bin/bash
#SBATCH -c 6 --job-name=phaseshift --array=0-200 --constraint=amd

export SIMG=/project/lofarvwf/Software/singularity/lofar_sksp_v4.0.2_znver2_znver2_noavx512_ddf_10_02_2023.sif

echo "Job landed on $(hostname)"

pattern="*.parset"
files=( $pattern )
N=${SLURM_ARRAY_TASK_ID}

singularity exec -B $PWD,/project,/home/lofarvwf-jdejong/scripts $SIMG DP3 ${files[${N}]}
echo "Launched script for ${files[${N}]}"
