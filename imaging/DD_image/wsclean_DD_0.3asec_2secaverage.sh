#!/bin/bash
#SBATCH -c 31
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=jurjendejong@strw.leidenuniv.nl
#SBATCH --constraint=amd
#SBATCH -p infinite
#SBATCH --constraint=mem950G

#SINGULARITY SETTINGS
SING_BIND=/project/lofarvwf/Share/jdejong,/home
SING_IMAGE_WSCLEAN=/home/lofarvwf-jdejong/singularities/lofar_sksp_v3.4_znver2_znver2_noavx512_cuda_ddf.sif

re="L[0-9][0-9][0-9][0-9][0-9][0-9]"
re_subband="([^.]+)"
if [[ $PWD =~ $re ]]; then OBSERVATION=${BASH_REMATCH}; fi

echo "Copy data to TMPDIR/wscleandata..."

mkdir "$TMPDIR"/wscleandata
cp -r /project/lofarvwf/Share/jdejong/output/ELAIS/${OBSERVATION}/apply_delaycal/applycal*.ms "$TMPDIR"/wscleandata
cp facets.reg "$TMPDIR"/wscleandata
cp master_merged.h5 "$TMPDIR"/wscleandata
cd "$TMPDIR"/wscleandata

echo "...Finished copying"

echo "Baseline-depenent averaging..."

for MS in applycal*.ms
do
  singularity exec -B ${SING_BIND} ${SING_IMAGE_WSCLEAN} DP3 \
  msin=${MS} \
  msout=bdavg_${MS} \
  steps=[bda] \
  bda.type=bdaaverager \
  bda.maxinterval=64. \
  bda.timebase=4000000
  rm -rf ${MS}
done

echo "...Finished baseline-dependent averaging"

singularity exec -B ${SING_BIND} ${SING_IMAGE_WSCLEAN} \
wsclean \
-update-model-required \
-temp-dir "$TMPDIR"/wscleandata \
-use-wgridder \
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
-name image_test \
-scale 0.15arcsec \
-taper-gaussian 0.4asec \
-niter 50000 \
-log-time \
-multiscale-scale-bias 0.7 \
-parallel-deconvolution 2600 \
-multiscale \
-multiscale-max-scales 9 \
-nmiter 9 \
-facet-regions facets.reg \
-apply-facet-solutions master_merged.h5 amplitude000,phase000 \
-parallel-gridding 6 \
-mem 16 \
-apply-facet-beam \
-facet-beam-update 600 \
-use-differential-lofar-beam \
-channels-out 3 \
-deconvolution-channels 3 \
-join-channels \
-fit-spectral-pol 3 \
-j 32 \
bdavg_*

rm -rf bdavg_*
tar cf output.tar *
cp "$TMPDIR"/wscleandata/output.tar ${OUT_DIR}

echo "----FINISHED----"
