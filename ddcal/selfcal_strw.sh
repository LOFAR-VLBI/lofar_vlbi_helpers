#!/bin/bash

MS=$1

#SINGULARITY SETTINGS
BIND=$PWD,/home/jurjendejong,/net/rijn
SIMG=/net/achterrijn/data1/sweijen/software/containers/lofar_sksp_v4.0.2_x86-64_cascadelake_cascadelake_avx512_mkl_cuda_ddf.sif

singularity exec -B $BIND $SIMG \
python /net/rijn/data2/rvweeren/LoTSS_ClusterCAL/lofar_facet_selfcal/facetselfcal.py \
-i selfcal \
--phaseupstations='core' \
--auto \
--makeimage-ILTlowres-HBA \
--targetcalILT='scalarphase' \
--stop=1 \
--no-beamcor \
--makeimage-fullpol \
--helperscriptspathh5merge=/home/jurjendejong/scripts/lofar_helpers \
${MS}
