#!/bin/bash
#SBATCH -c 31
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=jurjendejong@strw.leidenuniv.nl
#SBATCH --constraint=intel
#SBATCH -p infinite

#SINGULARITY SETTINGS
SING_BIND=/project/lofarvwf/Share/jdejong,/home
SING_IMAGE_WSCLEAN=/home/lofarvwf-jdejong/singularities/lofar_sksp_v4.0.0_cascadelake_cascadelake_avx512_mkl_cuda_ddf.sif

re="L[0-9][0-9][0-9][0-9][0-9][0-9]"
re_subband="([^.]+)"
if [[ $PWD =~ $re ]]; then OBSERVATION=${BASH_REMATCH}; fi

OUT_DIR=DI0.6image
cd ${OUT_DIR}

echo "Copy data to TMPDIR/wscleandata..."

mkdir "$TMPDIR"/wscleandata
cp -r /project/lofarvwf/Share/jdejong/output/ELAIS/${OBSERVATION}/apply_delaycal/applycal*.ms "$TMPDIR"/wscleandata
cd "$TMPDIR"/wscleandata

for MS in applycal*.ms
do
  singularity exec -B ${SING_BIND} ${SING_IMAGE_WSCLEAN} DP3 \
  msin=${MS} \
  msout=bdavg_${MS} \
  steps=[bda] \
  bda.type=bdaaverager \
  bda.maxinterval=64. \
  bda.timebase=4000000
done

echo "...Finished copying"

echo "----------START WSCLEAN----------"

singularity exec -B ${SING_BIND} ${SING_IMAGE_WSCLEAN} \
wsclean \
-update-model-required \
-minuv-l 80.0 \
-size 45000 45000 \
-weighting-rank-filter 3 \
-reorder \
-weight briggs -1.5 \
-parallel-reordering 6 \
-mgain 0.65 \
-data-column DATA \
-auto-mask 3 \
-auto-threshold 1.0 \
-pol i \
-name 0.6asec_I \
-scale 0.2arcsec \
-taper-gaussian 0.6asec \
-niter 150000 \
-log-time \
-multiscale-scale-bias 0.6 \
-parallel-deconvolution 2600 \
-multiscale \
-multiscale-max-scales 9 \
-nmiter 9 \
-mem 25 \
-channels-out 6 \
-join-channels \
-fit-spectral-pol 3 \
-deconvolution-channels 3 \
-j ${SLURM_CPUS_PER_TASK} \
-use-idg \
-grid-with-beam \
-use-differential-lofar-beam \
bdavg_applycal*.ms

echo "----------FINISHED WSCLEAN----------"

echo "Moving output images back to main folder"
tar cf output.tar *
cp "$TMPDIR"/wscleandata/output.tar ${OUT_DIR}

echo "COMPLETED JOB"
