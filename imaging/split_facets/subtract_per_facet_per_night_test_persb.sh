#!/bin/bash
#SBATCH -c 10
#SBATCH --job-name=subtract
#SBATCH --constraint=amd
#SBATCH --array=0-24

NIGHT=$1
FACETID=15

#SINGULARITY SETTINGS
SING_BIND=$( python3 $HOME/parse_settings.py --BIND )
SIMG=$( python3 $HOME/parse_settings.py --SIMG )

OUTPUTFOLDER=${PWD}/facet_${FACETID}/${NIGHT}
RUNFOLDER=${TMPDIR}/facet_${FACETID}/${NIGHT}_${SLURM_ARRAY_TASK_ID}

mkdir -p ${OUTPUTFOLDER}
mkdir -p ${RUNFOLDER}

pattern="apply*${NIGHT}*.ms"
MS_FILES=( $pattern )
SB=${MS_FILES[${SLURM_ARRAY_TASK_ID}]}

cp -r ${SB} ${RUNFOLDER}
cp poly_${FACETID}.reg ${RUNFOLDER}
cp facets_1.2.reg ${RUNFOLDER}
cp merged_${NIGHT}.h5 ${RUNFOLDER}
cp polygon_info.csv ${RUNFOLDER}

cd ${RUNFOLDER}

#subtract ms with wsclean for each facet
singularity exec -B ${SING_BIND} ${SIMG} python \
/home/lofarvwf-jdejong/scripts/lofar_helpers/subtract_with_wsclean/subtract_with_wsclean.py \
--mslist ${SB} \
--region poly_${FACETID}.reg \
--model_image_folder /project/lofarvwf/Share/jdejong/output/ELAIS/ALL_L/imaging/DD_1.2/${NIGHT}_2606/ \
--facets_predict facets_1.2.reg \
--h5parm_predict merged_${NIGHT}.h5 \
--applycal \
--forwidefield

mv sub*${NIGHT}*.ms ${OUTPUTFOLDER}

mkdir -p ${OUTPUTFOLDER}/SB_${SLURM_ARRAY_TASK_ID}
ls -1d * > ${OUTPUTFOLDER}/SB_${SLURM_ARRAY_TASK_ID}/sb_${SLURM_ARRAY_TASK_ID}.txt
mv *.log ${OUTPUTFOLDER}/SB_${SLURM_ARRAY_TASK_ID}
mv *.txt ${OUTPUTFOLDER}/SB_${SLURM_ARRAY_TASK_ID}
