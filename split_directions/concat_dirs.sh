#!/bin/bash
#SBATCH -N 1 -c 1 --job-name=concat --constraint=amd

SCRIPTS=/home/lofarvwf-jdejong/scripts/lofar_vlbi_helpers

export SIMG=/project/lofarvwf/Software/singularity/lofar_sksp_v4.1.0_znver2_znver2_noavx512_aocl3_cuda_ddf.sif

mkdir -p sub_parsets
mkdir -p concat_parsets
mv *.parset sub_parsets

singularity exec -B $PWD,/project,/home/lofarvwf-jdejong/scripts ${SIMG} python ${SCRIPTS}/split_directions/make_concat_parsets.py

for P in *.parset; do
  sbatch ${SCRIPTS}/split_directions/run_concat_parset.sh ${P}
done
