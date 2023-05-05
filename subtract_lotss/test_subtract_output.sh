#!/bin/bash
#SBATCH -N 1 -c 16 --job-name=test_subtract

SIMG=$( python $HOME/parse_settings.py --SIMG )
SING_BIND=$( python $HOME/parse_settings.py --BIND )
echo "SINGULARITY IS $SIMG"

MS_IN=$1

singularity exec -B $SING_BIND $SIMG DPPP msin=${MS_IN} msout=${MS_IN}_avg steps=[av] msout.storagemanager=dysco steps=[av] av.type=averager av.freqstep=16 av.timestep=16
singularity exec -B $SING_BIND $SIMG DPPP msin=sub6asec_${MS_IN}* msout=sub6asec_${MS_IN}_avg steps=[av] msout.storagemanager=dysco steps=[av] av.type=averager av.freqstep=16 av.timestep=16

singularity exec -B $SING_BIND $SIMG wsclean \
-scale 3arcsec \
-taper-gaussian 20arcsec \
-no-update-model-required \
-minuv-l 80 \
-size 8192 8192 \
-reorder \
-weight briggs -0.5 \
-cleanborder 1 \
-parallel-reordering 4 \
-mgain 0.75 \
-data-column DATA \
-auto-mask 2.5 \
-auto-threshold 0.5 \
-pol i -use-wgridder \
-name testimage \
-nmiter 10 \
-niter 100000 \
-maxuv-l 20e3 \
avg_${MS_IN}

mkdir test_sub6asec
mv avg_sub6asec_${MS_IN}_avg.sub.shift.avg.ms test_sub6asec
cd test_sub6asec

singularity exec -B $SING_BIND $SIMG wsclean \
-scale 3arcsec \
-taper-gaussian 20arcsec \
-no-update-model-required \
-minuv-l 80 \
-size 8192 8192 \
-reorder \
-weight briggs -0.5 \
-cleanborder 1 \
-parallel-reordering 4 \
-mgain 0.75 \
-data-column DATA \
-auto-mask 2.5 \
-auto-threshold 0.5 \
-pol i -use-wgridder \
-name testimage \
-nmiter 10 \
-niter 100000 \
-maxuv-l 20e3 \
avg_sub6asec_${MS_IN}.sub.shift.avg.ms