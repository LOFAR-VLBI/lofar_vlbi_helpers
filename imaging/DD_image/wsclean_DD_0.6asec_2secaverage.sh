#!/bin/bash
#SBATCH -c 48
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=jurjendejong@strw.leidenuniv.nl
#SBATCH --constraint=amd
#SBATCH -p infinite
#SBATCH --constraint=mem950G
#SBATCH --exclusive
#SBATCH --job-name=DD_0.3_imaging

OUT_DIR=$PWD

#SINGULARITY SETTINGS
SING_BIND=/project/lofarvwf/Share/jdejong,/home
SING_IMAGE_WSCLEAN=/home/lofarvwf-jdejong/singularities/lofar_sksp_v4.0.2_x86-64_cascadelake_cascadelake_avx512_mkl_cuda_ddf.sif

re="L[0-9][0-9][0-9][0-9][0-9][0-9]"
re_subband="([^.]+)"
if [[ $PWD =~ $re ]]; then OBSERVATION=${BASH_REMATCH}; fi

source /home/lofarvwf-jdejong/scripts/lofar_vlbi_helpers/imaging/prep_data/bda_0.6asec_2secaverage.sh

cp /project/lofarvwf/Share/jdejong/output/ELAIS/${OBSERVATION}/ddcal/selfcals/master_merged.h5 .

LIST=(bdaavg*.ms)

singularity exec -B ${SING_BIND} /project/lofarvwf/Public/fsweijen/lofar_sksp_v4.0.0_x84-64_generic_noavx512_mkl_cuda_ddf_test3.sif python \
/home/lofarvwf-jdejong/scripts/lofar_vlbi_helpers/helper_scripts/ds9facetgenerator.py \
--h5 master_merged.h5 \
--DS9regionout facets.reg \
--imsize 45000 \
--ms ${LIST[0]} \
--pixelscale 0.2

echo "Move data to tmpdir..."
mkdir "$TMPDIR"/wscleandata
mv master_merged.h5 "$TMPDIR"/wscleandata
mv facets.reg "$TMPDIR"/wscleandata
mv bdaavg*.ms "$TMPDIR"/wscleandata
cd "$TMPDIR"/wscleandata

echo "----------START WSCLEAN----------"

singularity exec -B ${SING_BIND} ${SING_IMAGE_WSCLEAN} \
wsclean \
-update-model-required \
-use-wgridder \
-minuv-l 80.0 \
-size 45000 45000 \
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
-scale 0.2arcsec \
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
-apply-facet-beam \
-facet-beam-update 600 \
-use-differential-lofar-beam \
-channels-out 3 \
-deconvolution-channels 3 \
-join-channels \
-fit-spectral-pol 3 \
bdaavg*.ms
#${OBSERVATION}_120_168MHz_applied_bda.ms

rm -rf bdaavg*.ms

tar cf output.tar *
cp "$TMPDIR"/wscleandata/output.tar ${OUT_DIR}

echo "----FINISHED----"
