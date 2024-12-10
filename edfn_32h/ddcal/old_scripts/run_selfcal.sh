#!/bin/bash
#SBATCH -c 6
#SBATCH --job-name=selfcal
#SBATCH --array=0-85
#SBATCH --constraint=intel

APPTAINERENV_MPLBACKEND=agg

re="L[0-9][0-9][0-9][0-9][0-9][0-9]"
if [[ $PWD =~ $re ]]; then OBSERVATION=${BASH_REMATCH}; fi

#SINGULARITY SETTINGS
SIMG=$( python $HOME/parse_settings.py --SIMG )
BIND=$( python $HOME/parse_settings.py --BIND )
echo "SINGULARITY IS $SIMG"
#SCRIPTS
lofar_facet_selfcal=$( python $HOME/parse_settings.py --facet_selfcal )

PATH_DIR=/project/lofarvwf/Share/jdejong/output/ELAIS/${OBSERVATION}/ddcal/all_directions
pattern="${PATH_DIR}/*.ms"
MS_FILES=( $pattern )
MS=${MS_FILES[${SLURM_ARRAY_TASK_ID}]}

re="P[0-9][0-9][0-9][0-9][0-9]"
if [[ ${MS} =~ $re ]]; then DIR=${BASH_REMATCH}; fi

mkdir -p ${DIR}_selfcal
mkdir -p ${DIR}_scalarphasediff

cd ${DIR}_scalarphasediff

cp -r ${MS} .

# scalarphasediff
singularity exec -B $BIND $SIMG \
python $lofar_facet_selfcal \
-i scalarphasediffcheck_${DIR} \
--forwidefield \
--phaseupstations='core' \
--msinnchan=120 \
--avgfreqstep=2 \
--skipbackup \
--uvmin=20000 \
--soltype-list="['scalarphasediff']" \
--solint-list="['10min']" \
--nchan-list="[6]" \
--docircular \
--uvminscalarphasediff=0 \
--stop=2 \
--soltypecycles-list="[0]" \
--imsize=1600 \
--skymodelpointsource=1.0 \
--stopafterskysolve \
--helperscriptspath=/project/lofarvwf/Software/lofar_facet_selfcal \
--helperscriptspathh5merge=/project/lofarvwf/Software/lofar_helpers \
*.ms

cd ../${DIR}_selfcal
cp -r ${MS} .

# selfcals
singularity exec -B $BIND $SIMG \
python /project/lofarvwf/Software/lofar_facet_selfcal/facetselfcal.py \
-i selfcal_${DIR} \
--phaseupstations='core' \
--auto \
--makeimage-ILTlowres-HBA \
--targetcalILT='scalarphase' \
--stop=12 \
--helperscriptspath=/project/lofarvwf/Software/lofar_facet_selfcal \
--helperscriptspathh5merge=/project/lofarvwf/Software/lofar_helpers \
*.ms

