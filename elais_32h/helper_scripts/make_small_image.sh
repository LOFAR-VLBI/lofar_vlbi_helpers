#!/bin/bash
#SBATCH -c 15 -t 20:00:00

MS=$1
H5=$2

#SINGULARITY SETTINGS
SING_BIND=$( python3 $HOME/parse_settings.py --BIND )
SIMG=$( python3 $HOME/parse_settings.py --SIMG )

singularity exec -B ${SING_BIND} ${SIMG} DP3 \
msin=${MS} \
msin.datacolumn=DATA \
msout=applied_MS.ms \
msout.storagemanager=dysco \
steps=[ac1,ac2] \
ac1.type=applycal \
ac1.parmdb=${H5} \
ac1.correction=phase000 \
ac2.type=applycal \
ac2.parmdb=${H5} \
ac2.correction=amplitude000

singularity exec -B ${SING_BIND} ${SIMG} wsclean \
-use-idg \
-update-model-required \
-minuv-l 80.0 \
-size 4000 4000 \
-weighting-rank-filter 3 \
-reorder \
-weight briggs -1.5 \
-parallel-reordering 6 \
-mgain 0.65 \
-data-column DATA \
-auto-mask 3 \
-auto-threshold 1.0 \
-pol i \
-name 1.2test \
-scale 0.4arcsec \
-taper-gaussian 1.2asec \
-niter 150000 \
-log-time \
-multiscale-scale-bias 0.6 \
-parallel-deconvolution 2600 \
-multiscale \
-multiscale-max-scales 9 \
-nmiter 9 \
-channels-out 6 \
-join-channels \
-fit-spectral-pol 3 \
-deconvolution-channels 3 \
-grid-with-beam \
-use-differential-lofar-beam \
applied_MS.ms
