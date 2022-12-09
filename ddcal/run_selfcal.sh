#!/bin/bash
#SBATCH -c 31
#SBATCH --job-name=selfcal
#SBATCH --array=0-85

APPTAINERENV_MPLBACKEND=agg

re="L[0-9][0-9][0-9][0-9][0-9][0-9]"
if [[ $PWD =~ $re ]]; then OBSERVATION=${BASH_REMATCH}; fi

#SINGULARITY SETTINGS
BIND=$PWD,/project,/home/lofarvwf-jdejong/scripts
SIMG=/project/lofarvwf/Software/singularity/lofar_sksp_v3.4_x86-64_generic_noavx512_ddf.sif

PATH_DIR=/project/lofarvwf/Share/jdejong/output/ELAIS/${OBSERVATION}/ddcal/all_directions
pattern="${PATH_DIR}/*.ms"
MS_FILES=( $pattern )
MS=${MS_FILES[${SLURM_ARRAY_TASK_ID}]}

re="P[0-9][0-9][0-9][0-9][0-9]"
if [[ ${MS} =~ $re ]]; then DIR=${BASH_REMATCH}; fi

mkdir -p ${DIR}
cd ${DIR}

cp -r ${MS} .

singularity exec -B $BIND $SIMG \
python /home/lofarvwf-jdejong/scripts/lofar_facet_selfcal/facetselfcal.py \
-i selfcal_${DIR} \
--phaseupstations='core' \
--auto \
--makeimage-ILTlowres-HBA \
--targetcalILT='scalarphase' \
--stop=12 \
--helperscriptspath=/home/lofarvwf-jdejong/scripts/lofar_facet_selfcal \
--helperscriptspathh5merge=/home/lofarvwf-jdejong/scripts/lofar_helpers \
*.ms
