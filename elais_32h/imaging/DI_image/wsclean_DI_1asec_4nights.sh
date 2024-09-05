#!/bin/bash
#SBATCH -c 31
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=jurjendejong@strw.leidenuniv.nl
#SBATCH --constraint=intel
#SBATCH --job-name=DI_1_imaging
#SBATCH -p infinite

#SINGULARITY SETTINGS
SING_BIND=$( python $HOME/parse_settings.py --BIND )
SIMG=$( python $HOME/parse_settings.py --SIMG )

re="L[0-9][0-9][0-9][0-9][0-9][0-9]"
re_subband="([^.]+)"
if [[ $PWD =~ $re ]]; then OBSERVATION=${BASH_REMATCH}; fi

source /home/lofarvwf-jdejong/scripts/lofar_vlbi_helpers/imaging/prep_data/1asec_4nights.sh

echo "----------START WSCLEAN----------"

singularity exec -B ${SING_BIND} ${SIMG} \
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
-niter 150000 \
-log-time \
-multiscale-scale-bias 0.6 \
-parallel-deconvolution 2600 \
-multiscale \
-multiscale-max-scales 9 \
-nmiter 12 \
-channels-out 6 \
-join-channels \
-fit-spectral-pol 3 \
-deconvolution-channels 3 \
-use-idg \
-grid-with-beam \
-use-differential-lofar-beam \
avg*.ms

echo "----------FINISHED WSCLEAN----------"
