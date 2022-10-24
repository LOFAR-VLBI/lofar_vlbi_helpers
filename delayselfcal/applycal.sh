#!/bin/bash
#SBATCH -N 1 -c 4 --job-name=applycal

MSIN=$1
H5=$2

SIMG=/home/lofarvwf-jdejong/singularities/lofar_sksp_fedora31_ddf_fixed.sif

singularity exec -B $PWD,/project,/home/lofarvwf-jdejong/scripts $SIMG \
python applycal.py \
--msin ${MSIN} \
--msout applycal_${MSIN} \
--h5 ${H5}