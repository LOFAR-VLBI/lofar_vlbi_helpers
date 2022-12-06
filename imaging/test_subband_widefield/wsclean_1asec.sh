#!/bin/bash
#SBATCH -c 31
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=jurjendejong@strw.leidenuniv.nl
#SBATCH --constraint=intel

#MSLIST
ls -1 -d applycal* > mslist.txt

#SINGULARITY SETTINGS
SING_BIND=/project/lofarvwf/Share/jdejong,/home
SING_IMAGE_WSCLEAN=/home/lofarvwf-jdejong/singularities/idgtest_23_02_2022.sif

OUT_DIR=$PWD

echo "Average data in DPPP..."

for MS in applycal*.ms
do
  singularity exec -B ${SING_BIND} ${SING_IMAGE_WSCLEAN} DPPP \
  msin=${MS} \
  msin.datacolumn=DATA \
  msout.overwrite=True \
  msout.storagemanager=dysco \
  msout.writefullresflag=False \
  steps=[avg] \
  avg.type=averager \
  avg.freqstep=4 \
  avg.timestep=2
done

echo "...Finished averaging"

echo "Copy data to TMPDIR/wscleandata..."

mkdir "$TMPDIR"/wscleandata
cp -r applycal*.ms "$TMPDIR"/wscleandata
cd "$TMPDIR"/wscleandata

echo "...Finished copying"

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
-niter 200 \
-log-time \
-multiscale-scale-bias 0.6 \
-parallel-deconvolution 2600 \
-multiscale \
-multiscale-max-scales 9 \
-nmiter 1 \
-mem 25 \
-channels-out 6 \
-join-channels \
-fit-spectral-pol 3 \
-deconvolution-channels 3 \
-j ${SLURM_CPUS_PER_TASK} \
-use-idg \
-grid-with-beam \
-use-differential-lofar-beam \
applycal*.ms

echo "----------FINISHED WSCLEAN----------"

echo "Moving output images back to main folder"
tar cf output.tar *
cp "$TMPDIR"/wscleandata/output.tar ${OUT_DIR}

echo "COMPLETED JOB"