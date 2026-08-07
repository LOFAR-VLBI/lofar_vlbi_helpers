#!/bin/bash
#SBATCH -c 32 -t 48:00:00 -p normal,infinite
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=jurjendejong@strw.leidenuniv.nl

######################
######## INPUT #######
######################

FACET=$1
RESOLUTION=$2
SCRIPT_DIR=/home/lofarvwf-jdejong/scripts/lofar_vlbi_helpers/edfn
POLYGON=/project/lofarvwf/Share/jdejong/output/EUCLID/edfn_centre/final_imaging/polygons/poly_${FACET}.reg

######################
######################

source $SCRIPT_DIR/setup.sh --no-git --no-sing

RUNDIR=$TMPDIR
OUTDIR=$PWD/${RESOLUTION}arcsec
SCALE=$(awk "BEGIN {printf \"%.1f\", $RESOLUTION / 3}")

mkdir -p ${OUTDIR}

cp $SING_IMG $RUNDIR
cp -r facet_${FACET}_sva.ms $RUNDIR
cd $RUNDIR

singularity exec -B /project/lofarvwf $(basename ${SING_IMG}) \
python ${VLBI_DATA_ROOT}/scripts/estimate_facet_size.py \
--region ${POLYGON} \
--resolution ${RESOLUTION} \
--filename info.json \
--pixel_size ${SCALE} \
--padding 1.025

read -r xsize ysize < <(jq -r '.image_size | @tsv' info.json)

singularity exec -B $PWD $(basename ${SING_IMG}) wsclean \
-gridder wgridder \
-no-update-model-required \
-minuv-l 80.0 \
-size $xsize $ysize \
-weighting-rank-filter 3 \
-reorder \
-weight briggs -1.4 \
-parallel-reordering 6 \
-mgain 0.65 \
-data-column DATA \
-auto-mask 2.5 \
-auto-threshold 1.0 \
-pol i \
-name facet_${FACET} \
-scale ${SCALE}arcsec \
-niter 150000 \
-log-time \
-multiscale-scale-bias 0.6 \
-parallel-deconvolution 2600 \
-multiscale \
-multiscale-max-scales 9 \
-nmiter 10 \
-parallel-gridding 6 \
-channels-out 12 \
-join-channels \
-fit-spectral-pol 5 \
-apply-primary-beam \
-use-differential-lofar-beam \
-local-rms -local-rms-window 50 \
-mem 75 \
-taper-gaussian ${RESOLUTION}asec \
*.ms

cp *MFS*.fits ${OUTDIR}
