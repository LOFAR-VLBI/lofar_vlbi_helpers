#!/bin/bash
#SBATCH -c 60
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=jurjendejong@strw.leidenuniv.nl
#SBATCH --constraint=amd
#SBATCH -p infinite
#SBATCH --exclusive
#SBATCH --constraint=mem950G
#SBATCH --job-name=DD_1_imaging

#EXAMPLE: 'L12312,L87654,...'
NIGHTS=$1

OUT_DIR=$PWD

#SINGULARITY SETTINGS
SING_BIND=$( python3 $HOME/parse_settings.py --BIND )
SIMG=$( python3 $HOME/parse_settings.py --SIMG )

FACET=facets.reg
H5=merged_L686962.h5

echo "----------START WSCLEAN----------"

singularity exec -B ${SING_BIND} ${SIMG} \
wsclean \
-update-model-required \
-gridder wgridder \
-minuv-l 80.0 \
-size 60000 60000 \
-weighting-rank-filter 3 \
-reorder \
-weight briggs -1.5 \
-parallel-reordering 6 \
-mgain 0.65 \
-data-column DATA \
-auto-mask 2.5 \
-auto-threshold 1.0 \
-pol i \
-name 0.4image \
-scale 0.15arcsec \
-taper-gaussian 0.4asec \
-niter 150000 \
-log-time \
-multiscale-scale-bias 0.7 \
-parallel-deconvolution 2600 \
-multiscale \
-multiscale-max-scales 9 \
-nmiter 9 \
-facet-regions ${FACET} \
-apply-facet-solutions ${H5} amplitude000,phase000 \
-parallel-gridding 6 \
-apply-facet-beam \
-facet-beam-update 600 \
-use-differential-lofar-beam \
-channels-out 6 \
-deconvolution-channels 3 \
-join-channels \
-fit-spectral-pol 3 \
-dd-psf-grid 3 3 \
*.ms

#rm -rf avg*.ms
#
#tar cf output.tar *
#cp "$TMPDIR"/wscleandata/output.tar ${OUT_DIR}
#
#cd ${OUT_DIR}
#tar -xf output.tar *fits

echo "----FINISHED----"
