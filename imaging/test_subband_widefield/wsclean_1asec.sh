#!/bin/bash
#SBATCH -c 31
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=jurjendejong@strw.leidenuniv.nl

#INPUT
MSIN=$1

SING_BIND=/project/lofarvwf/Share/jdejong,/home
SING_IMAGE_WSCLEAN=/home/lofarvwf-jdejong/singularities/idgtest_23_02_2022.sif

#echo "Copy data to TMPDIR/wscleandata"
#
#mkdir "$TMPDIR"/wscleandata
#cp -r ${MSIN} "$TMPDIR"/wscleandata
##cp /project/lofarvwf/Share/jdejong/output/LB_test_data/facetsscreen.reg "$TMPDIR"/wscleandata
##cp /project/lofarvwf/Share/jdejong/output/LB_test_data/merged_testpython3_withCS_jan22.h5 "$TMPDIR"/wscleandata
#cd "$TMPDIR"/wscleandata

echo "----------START WSCLEAN----------"

singularity exec -B ${SING_BIND} ${SING_IMAGE_WSCLEAN} \
wsclean \
-update-model-required \
-minuv-l 80.0 \
-size 22500 22500 \
-weighting-rank-filter 3 \
-reorder \
-weight briggs -1.5 \
-parallel-reordering 6 \
-mgain 0.65 \
-data-column DATA \
-auto-mask 3 \
-auto-threshold 1.0 \
-pol i \
-name 1.2asec_I \
-scale 0.4arcsec \
-taper-gaussian 1.2asec \
-niter 50000 \
-log-time \
-multiscale-scale-bias 0.6 \
-parallel-deconvolution 2600 \
-multiscale \
-multiscale-max-scales 9 \
-nmiter 6 \
-mem 25 \
-channels-out 1 \
-j ${SLURM_CPUS_PER_TASK} \
-use-idg \
-grid-with-beam \
-use-differential-lofar-beam \
${MSIN}

echo "----------FINISHED WSCLEAN----------"

#echo "Moving output images back to main folder"
#tar cf output.tar *MFS*.fits
#cp "$TMPDIR"/wscleandata/output.tar $1

echo "COMPLETED JOB"