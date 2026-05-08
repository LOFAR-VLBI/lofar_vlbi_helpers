#!/bin/bash
#SBATCH -c 16 -p infinite,normal

MSIN=$1
MSOUT=$2
SOLS=$3
SIMG=$4

singularity exec -B $PWD ${SIMG} \
applycal \
--msin ${MSIN} \
--h5 ${SOLS} \
--bitrate 6 \
--msout ${MSOUT}
