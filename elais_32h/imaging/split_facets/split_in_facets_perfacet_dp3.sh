#!/bin/bash
#SBATCH -c 1

#SINGULARITY SETTINGS
SING_BIND=$( python3 $HOME/parse_settings.py --BIND )
SIMG=$( python3 $HOME/parse_settings.py --SIMG )
SCRIPT_DIR=/home/lofarvwf-jdejong/scripts/lofar_vlbi_helpers/imaging/split_facets
LOFAR_HELPERS=$( python3 $HOME/parse_settings.py --lofar_helpers )

FACETNUMBER=$1

echo "COPY SOLUTION FILES"
cp /project/lofarvwf/Share/jdejong/output/ELAIS/ALL_L/dd_solutions/mergedsolutions/merged_L??????.h5 .
mkdir -p solutions
cp /project/lofarvwf/Share/jdejong/output/ELAIS/ALL_L/dd_solutions/solutions/*.h5 solutions

echo "COPY SKYMODELS"
cp -r /project/lofarvwf/Share/jdejong/output/ELAIS/ALL_L/new_ddcal/allselfcals/skymodels .

LISTMS=(/project/lofarvwf/Share/jdejong/output/ELAIS/ALL_L/apply_delaycal/flag*.ms)
H5S=(*.h5)

#make facets based on merged h5
singularity exec -B ${SING_BIND} ${SIMG} python \
/home/lofarvwf-jdejong/scripts/lofar_vlbi_helpers/extra_scripts/ds9facetgenerator.py \
--h5 ${H5S[0]} \
--DS9regionout facets_1.2.reg \
--imsize 22500 \
--ms ${LISTMS[0]} \
--pixelscale 0.4

#loop over facets from merged h5
singularity exec -B ${SING_BIND} ${SIMG} python \
${LOFAR_HELPERS}/ds9_helpers/split_polygon_facets.py \
--h5 ${H5S[0]} \
--reg facets_1.2.reg \
--extra_boundary 0.1

# give night names
sbatch ${SCRIPT_DIR}/subtract_perfacet_pernight_persb_dp3.sh ${FACETNUMBER} L686962
sbatch ${SCRIPT_DIR}/subtract_perfacet_pernight_persb_dp3.sh ${FACETNUMBER} L769393
sbatch ${SCRIPT_DIR}/subtract_perfacet_pernight_persb_dp3.sh ${FACETNUMBER} L798074
sbatch ${SCRIPT_DIR}/subtract_perfacet_pernight_persb_dp3.sh ${FACETNUMBER} L816272
