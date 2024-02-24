#!/bin/bash
#SBATCH -c 10

#SINGULARITY SETTINGS
SING_BIND=$( python3 $HOME/parse_settings.py --BIND )
SIMG=$( python3 $HOME/parse_settings.py --SIMG )
SCRIPT_DIR=/home/lofarvwf-jdejong/scripts/lofar_vlbi_helpers/imaging/split_facets
LOFAR_HELPERS=$( python3 $HOME/parse_settings.py --lofar_helpers )

echo "COPY SOLUTION FILES"
cp /project/lofarvwf/Share/jdejong/output/ELAIS/ALL_L/dd_solutions/merged_L??????.h5 . #TODO: pol?

LISTMS=(/project/lofarvwf/Share/jdejong/output/ELAIS/ALL_L/apply_delaycal/*L68*.ms)
H5S=(*L68*.h5)

#make facets based on merged h5
singularity exec -B ${SING_BIND} ${SIMG} python \
/home/lofarvwf-jdejong/scripts/lofar_vlbi_helpers/extra_scripts/ds9facetgenerator.py \
--h5 ${H5S[0]} \
--DS9regionout facets_0.6.reg \
--imsize 45000 \
--ms ${LISTMS[0]} \
--pixelscale 0.2

#loop over facets from merged h5
singularity exec -B ${SING_BIND} ${SIMG} python \
${LOFAR_HELPERS}/ds9_helpers/split_polygon_facets.py \
--h5 ${H5S[0]} \
--reg facets_0.6.reg \
--extra_boundary 0.1

# give night names
COUNT=$( ls -1d poly_*.reg | wc -l )
for ((i=1;i<=COUNT;i++)); do
  sbatch ${SCRIPT_DIR}/subtract_perfacet_pernight_persb_0.6.sh $i L686962
  sbatch ${SCRIPT_DIR}/subtract_perfacet_pernight_persb_0.6.sh $i L769393
  sbatch ${SCRIPT_DIR}/subtract_perfacet_pernight_persb_0.6.sh $i L798074
  sbatch ${SCRIPT_DIR}/subtract_perfacet_pernight_persb_0.6.sh $i L816272
done