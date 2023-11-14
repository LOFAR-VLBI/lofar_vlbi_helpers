#!/bin/bash
#SBATCH -c 31
#SBATCH --mail-type=FAIL,END
#SBATCH --mail-user=jurjendejong@strw.leidenuniv.nl
#SBATCH --job-name=imaging_facet
#SBATCH -p normal

FACET=facet_$1

OUTPUT=$PWD
RUNDIR=$TMPDIR/DIR633878_${FACET}_06
mkdir -p $RUNDIR
cp /project/lofarvwf/Software/singularity/lofar_sksp_v4.4.0_znver2_znver2_aocl4.sif $RUNDIR
cp -r avg0.6_*.ms $RUNDIR

cd $RUNDIR

singularity exec -B /project/lofarvwf/Share/jdejong/,$PWD lofar_sksp_v4.4.0_znver2_znver2_aocl4.sif wsclean \
-gridder wgridder \
-no-update-model-required \
-minuv-l 80.0 \
-size 22500 22500 \
-weighting-rank-filter 3 \
-reorder \
-parallel-reordering 4 \
-weight briggs -1.5 \
-mgain 0.75 \
-data-column DATA \
-auto-mask 2.5 \
-auto-threshold 1.0 \
-pol i \
-name ${FACET}_0.6 \
-scale 0.2arcsec \
-niter 500000 \
-log-time \
-multiscale-scale-bias 0.6 \
-parallel-deconvolution 2600 \
-multiscale \
-multiscale-max-scales 9 \
-nmiter 9 \
-parallel-gridding 4 \
-channels-out 6 \
-join-channels \
-fit-spectral-pol 3 \
-local-rms -local-rms-window 50 \
-taper-gaussian 0.6asec \
*.ms

cp *.fits $OUTPUT
