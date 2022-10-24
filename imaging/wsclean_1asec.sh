#!/bin/bash
#SBATCH -c 48
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=jurjendejong@strw.leidenuniv.nl

#INPUT
MSIN=$1

SING_BIND=/project/lofarvwf/Share/jdejong,/home
SING_IMAGE_WSCLEAN=/home/lofarvwf-jdejong/singularities/idgtest_23_02_2022.sif

mkdir "$TMPDIR"/wscleandata
cp -r /project/lofarvwf/Share/jdejong/output/LB_test_data/$${MSIN} "$TMPDIR"/wscleandata
#cp /project/lofarvwf/Share/jdejong/output/LB_test_data/facetsscreen.reg "$TMPDIR"/wscleandata
#cp /project/lofarvwf/Share/jdejong/output/LB_test_data/merged_testpython3_withCS_jan22.h5 "$TMPDIR"/wscleandata
cd "$TMPDIR"/wscleandata

singularity exec -B ${SING_BIND} ${SING_IMAGE_WSCLEAN} \
wsclean \
-update-model-required \
-temp-dir "$TMPDIR"/wscleandata \
-use-wgridder \
-minuv-l 80.0 \
-size 20000 20000 \
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
-scale 0.4arcsec \
-taper-gaussian 1asec \
-niter 50000 \
-log-time \
-multiscale-scale-bias 0.7 \
-parallel-deconvolution 2600 \
-multiscale \
-multiscale-max-scales 9 \
-nmiter 1 \
-parallel-gridding $1 \
-mem ${MEM} \
-apply-facet-beam \
-facet-beam-update 600 \
-use-differential-lofar-beam \
-channels-out 3 \
-deconvolution-channels 3 \
-join-channels \
-j $2 \
${MSIN}

#rm -rf sub6asec_L686962_SB001_uv_12CFFDDA8t_1*
#rm merged_testpython3_withCS_jan22.h5
#tar cf output.tar *MFS*.fits
#cp "$TMPDIR"/wscleandata/output.tar $1

echo "----FINISHED----"
