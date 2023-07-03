#!/bin/bash
#SBATCH -c 10 -t 48:00:00

SB=$1

mkdir ${SB}_folder
mv ${SB} ${SB}_folder
cd ${SB}_folder

#subtract ms with wsclean for each facet
singularity exec -B ${SING_BIND} ${SIMG} python \
/home/lofarvwf-jdejong/scripts/lofar_helpers/subtract_with_wsclean/subtract_with_wsclean.py \
--mslist ${SB} \
--region ../../poly_${SLURM_ARRAY_TASK_ID}.reg \
--model_image_folder ../../ \
--facets_predict ../../facets_1.2.reg \
--h5parm_predict ../merged_${NIGHT}.h5 \
--forwidefield

rm -rf ${SB}
mv sub*.ms ../
