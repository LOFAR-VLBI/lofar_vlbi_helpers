#!/bin/bash
#SBATCH -c 60
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=jurjendejong@strw.leidenuniv.nl
#SBATCH --constraint=amd
#SBATCH -p infinite
#SBATCH --exclusive
#SBATCH --constraint=mem950G
#SBATCH --job-name=DD_1_imaging

#EXAMPLE: 'L12312,L87654,...'
NIGHTS=$1

OUT_DIR=$PWD

#SINGULARITY SETTINGS
SING_BIND=$( python3 $HOME/parse_settings.py --BIND )
SIMG=$( python3 $HOME/parse_settings.py --SIMG )

IFS=',' ;for L in $NIGHTS
do
  cp /project/lofarvwf/Share/jdejong/output/ELAIS/ALL_L/ddcal/merged_${L}.h5 .
  cp -r /project/lofarvwf/Share/jdejong/output/ELAIS/ALL_L/apply_delaycal/applycal*${L}*.ms .

  LIST=(applycal*${L}*.ms)

  singularity exec -B ${SING_BIND} ${SIMG} python \
  /home/lofarvwf-jdejong/scripts/lofar_vlbi_helpers/extra_scripts/ds9facetgenerator.py \
  --h5 merged_$L.h5 \
  --DS9regionout facets_${L}.reg \
  --imsize 60000 \
  --ms ${LIST[0]} \
  --pixelscale 0.15

  FACET=facets_${L}.reg
done

#echo "Move data to tmpdir..."
#mkdir "$TMPDIR"/wscleandata
#mv *.h5 "$TMPDIR"/wscleandata
#mv facets*.reg "$TMPDIR"/wscleandata
#mv avg*.ms "$TMPDIR"/wscleandata
#cd "$TMPDIR"/wscleandata

#aoflagger
for MS in applycal*.ms
do
  singularity exec -B ${SING_BIND} ${SING_IMAGE} aoflagger ${MS}
done

singularity exec -B ${SING_BIND} ${SIMG} \
python /home/lofarvwf-jdejong/scripts/lofar_vlbi_helpers/extra_scripts/mapping_solutions_ms.py $NIGHTS

H5_VECTOR=$(cat  h5list.txt |tr "\n" ",")
MS_VECTOR=$(cat  mslist.txt |tr "\n" " ")

echo "----------START WSCLEAN----------"

singularity exec -B ${SING_BIND} ${SIMG} \
wsclean \
-update-model-required \
-gridder wgridder \
-minuv-l 80.0 \
-size 60000 60000 \
-weighting-rank-filter 3 \
-reorder \
-weight briggs -1.5 \
-parallel-reordering 6 \
-mgain 0.65 \
-data-column DATA \
-auto-mask 2.5 \
-auto-threshold 1.0 \
-pol i \
-name 0.6image \
-scale 0.2arcsec \
-taper-gaussian 0.15asec \
-niter 150000 \
-log-time \
-multiscale-scale-bias 0.7 \
-parallel-deconvolution 2600 \
-multiscale \
-multiscale-max-scales 9 \
-nmiter 9 \
-facet-regions ${FACET} \
-apply-facet-solutions ${H5_VECTOR} amplitude000,phase000 \
-parallel-gridding 6 \
-apply-facet-beam \
-facet-beam-update 600 \
-use-differential-lofar-beam \
-channels-out 6 \
-deconvolution-channels 3 \
-join-channels \
-fit-spectral-pol 3 \
-dd-psf-grid 3 3 \
${MS_VECTOR}

#rm -rf avg*.ms
#
#tar cf output.tar *
#cp "$TMPDIR"/wscleandata/output.tar ${OUT_DIR}
#
#cd ${OUT_DIR}
#tar -xf output.tar *fits

echo "----FINISHED----"
