#!/bin/bash
#SBATCH -N 1 -c 16 --job-name=test_subtract -t 48:00:00

SIMG=$( python3 $HOME/parse_settings.py --SIMG )
SING_BIND=$( python3 $HOME/parse_settings.py --BIND )
echo "SINGULARITY IS $SIMG"

singularity exec -B $SING_BIND $SIMG DP3 msin=../*.ms msout=test.ms steps=[av,filt] msout.storagemanager=dysco \
av.type=averager av.freqstep=16 av.timestep=16 \
filt.type=filter filt.baseline='[CR]S*&&'

singularity exec -B $SING_BIND $SIMG wsclean \
-scale 3arcsec \
-taper-gaussian 20arcsec \
-no-update-model-required \
-minuv-l 80 \
-size 9000 9000 \
-reorder \
-weight briggs -0.5 \
-parallel-reordering 4 \
-mgain 0.75 \
-data-column DATA \
-auto-mask 2.5 \
-auto-threshold 0.5 \
-pol i \
-gridder wgridder \
-name testimage \
-nmiter 10 \
-niter 100000 \
-maxuv-l 20e3 \
test.ms
