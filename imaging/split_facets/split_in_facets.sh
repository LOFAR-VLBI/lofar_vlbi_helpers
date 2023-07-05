#!/bin/bash
#SBATCH -c 2

#SINGULARITY SETTINGS
SING_BIND=$( python3 $HOME/parse_settings.py --BIND )
SIMG=$( python3 $HOME/parse_settings.py --SIMG )
SCRIPT_DIR=/home/lofarvwf-jdejong/scripts/lofar_vlbi_helpers/imaging/split_facets

echo "COPY DATA"
SOURCEDIR=/project/lofarvwf/Share/jdejong/output/ELAIS/ALL_L/apply_delaycal
MAX_PARALLEL=8
nroffiles=$(ls -1d $SOURCEDIR/*.ms|wc -w)
setsize=$(( nroffiles/MAX_PARALLEL + 1 ))
ls -1d $SOURCEDIR/* | xargs -n $setsize | while read workset; do
  echo "COPY $workset"
  cp -r $workset .
done
wait

echo "COPY SOLUTION FILES"
cp /project/lofarvwf/Share/jdejong/output/ELAIS/ALL_L/ddcal/merged_L??????.h5 .

LISTMS=(*.ms)
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
${SCRIPT_DIR}/split_facets.py \
--h5 ${H5S[0]} \
--reg facets_1.2.reg #TODO: CHANGE THIS FOR OTHER RESOLUTIONS

sbatch ${SCRIPT_DIR}/subtract_per_facet_per_sb.sh
