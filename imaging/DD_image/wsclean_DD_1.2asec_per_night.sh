#!/bin/bash
#SBATCH -c 31
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=jurjendejong@strw.leidenuniv.nl
#SBATCH --constraint=amd
#SBATCH -p infinite
#SBATCH --job-name=DD_1_imaging

#SINGULARITY SETTINGS
SING_BIND=$( python3 $HOME/parse_settings.py --BIND )
SIMG=/project/lofarvwf/Software/singularity/lofar_sksp_v4.0.2_znver2_znver2_noavx512_ddf_10_02_2023.sif

NIGHT=$1 # L*

OUT_DIR=$PWD/${NIGHT}

mkdir -p ${OUT_DIR}
cp -r avg*${NIGHT}*.ms ${OUT_DIR}
cp merged_${NIGHT}.h5 ${OUT_DIR}
cp facets.reg ${OUT_DIR}

cd ${OUT_DIR}

LIST=(*.ms)

singularity exec -B ${SING_BIND} ${SIMG} python \
/home/lofarvwf-jdejong/scripts/lofar_vlbi_helpers/extra_scripts/ds9facetgenerator.py \
--h5 merged_${NIGHT}.h5 \
--DS9regionout facets.reg \
--imsize 22500 \
--ms ${LIST[0]} \
--pixelscale 0.4

echo "Move data to tmpdir..."
mkdir "$TMPDIR"/wscleandata
mv merged_${NIGHT}.h5 "$TMPDIR"/wscleandata
mv facets.reg "$TMPDIR"/wscleandata
mv *.ms "$TMPDIR"/wscleandata
cd "$TMPDIR"/wscleandata

#extra flagging
for M in *.ms
do
  cp -r ${FROM}/${M} ${TO} && wait
  singularity exec -B ${SING_BIND} ${SIMG} aoflagger ${M}
  singularity exec -B ${SING_BIND} ${SIMG} DP3 msin=${M} \
  steps=[filter] \
  filter.baseline=\!RS409HBA \
  filter.remove=true \
  msin.datacolumn=DATA \
  msout.storagemanager=dysco
done

echo "----------START WSCLEAN----------"

singularity exec -B ${SING_BIND} ${SIMG} \
wsclean \
-update-model-required \
-gridder wgridder \
-minuv-l 80.0 \
-size 22500 22500 \
-weighting-rank-filter 3 \
-reorder \
-weight briggs -1.5 \
-parallel-reordering 6 \
-mgain 0.65 \
-data-column DATA \
-auto-mask 2.5 \
-auto-threshold 1.0 \
-pol i \
-name 1.2image \
-scale 0.4arcsec \
-taper-gaussian 1.2asec \
-niter 100000 \
-log-time \
-multiscale-scale-bias 0.7 \
-parallel-deconvolution 2600 \
-multiscale \
-multiscale-max-scales 9 \
-nmiter 9 \
-facet-regions facets.reg \
-apply-facet-solutions merged_${NIGHT}.h5 amplitude000,phase000 \
-parallel-gridding 6 \
-apply-facet-beam \
-facet-beam-update 600 \
-use-differential-lofar-beam \
-channels-out 6 \
-deconvolution-channels 3 \
-join-channels \
-fit-spectral-pol 3 \
avg*.ms

rm -rf *.ms
#
tar cf output.tar *
cp "$TMPDIR"/wscleandata/output.tar ${OUT_DIR}

cd ${OUT_DIR}
tar -xf output.tar *fits

echo "----FINISHED----"
