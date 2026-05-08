#!/bin/bash
#SBATCH -c 48
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=jurjendejong@strw.leidenuniv.nl
#SBATCH --job-name=1asec_imaging
#SBATCH -p normal

######################
######## INPUT #######
######################

MERGEDH5=$1
MS=$2

######################
######################

RUNDIR=/tmp/wsclean
OUTDIR=$PWD/1asec_imaging

mkdir -p $RUNDIR
cp -r ${MS} $RUNDIR
cp ${MERGEDH5} $RUNDIR

cd $RUNDIR

wget https://public.spider.surfsara.nl/project/lofarvwf/fsweijen/containers/flocs_v6.0.0.alpha_cascadelake_cascadelake.sif
git clone https://github.com/LOFAR-VLBI/lofar_vlbi_helpers

singularity exec -B $PWD flocs_v6.0.0.alpha_cascadelake_cascadelake.sif python \
lofar_vlbi_helpers/elais_32h/helper_scripts/ds9facetgenerator.py \
--h5 $(basename ${MERGEDH5}) \
--DS9regionout facets.reg \
--imsize 25000 \
--ms $(basename ${MS}) \
--pixelscale 0.4

singularity exec -B $PWD flocs_v6.0.0.alpha_cascadelake_cascadelake.sif \
wsclean \
-update-model-required \
-gridder wgridder \
-minuv-l 80.0 \
-size 22500 22500 \
-weighting-rank-filter 3 \
-reorder \
-weight briggs -1.5 \
-parallel-reordering 6 \
-mgain 0.8 \
-data-column DATA \
-auto-mask 2.5 \
-auto-threshold 1.0 \
-pol i \
-name 1.2image \
-scale 0.4arcsec \
-taper-gaussian 1.2asec \
-niter 200000 \
-log-time \
-multiscale-scale-bias 0.7 \
-parallel-deconvolution 2600 \
-multiscale \
-multiscale-max-scales 9 \
-nmiter 10 \
-facet-regions facets.reg \
-apply-facet-solutions $(basename ${MERGEDH5}) amplitude000,phase000 \
-parallel-gridding 6 \
-apply-facet-beam \
-facet-beam-update 600 \
-use-differential-lofar-beam \
-channels-out 12 \
-join-channels \
-fit-spectral-pol 9 \
-local-rms \
-local-rms-window 50 \
-scalar-visibilities \
-dd-psf-grid 3 3 \
$(basename ${MS})

cp *.fits $OUTDIR
cd $OUTDIR
rm *-00??-residual*.fits
rm *-00??-dirty*.fits
rm *d000?-*.fits
