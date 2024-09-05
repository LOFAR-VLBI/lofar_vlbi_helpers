#!/bin/bash
#SBATCH -c 10 -t 48:00:00

SB=$1
NIGHT=$2
POLYREG=$3

SING_BIND=$( python3 $HOME/parse_settings.py --BIND )
SIMG=$( python3 $HOME/parse_settings.py --SIMG )

mkdir ${SB}_folder
mv ${SB} ${SB}_folder
cd ${SB}_folder

#subtract ms with wsclean for each facet
singularity exec -B ${SING_BIND} ${SIMG} python \
/project/lofarvwf/Software/lofar_helpers/subtract_with_wsclean/subtract_with_wsclean.py \
--mslist ${SB} \
--region ../../${POLYREG} \
--model_image_folder /project/lofarvwf/Share/jdejong/output/ELAIS/ALL_L/imaging/DD_1.2/${NIGHT}_2606/ \
--facets_predict ../../facets_1.2.reg \
--h5parm_predict ../merged_${NIGHT}.h5 \
--forwidefield

rm -rf ${SB}
mv sub*.ms ../
