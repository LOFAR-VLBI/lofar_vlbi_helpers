#!/bin/bash
#SBATCH -c 5 -t 24:00:00

#SINGULARITY SETTINGS
SING_BIND=$( python3 $HOME/parse_settings.py --BIND )
SIMG=$( python3 $HOME/parse_settings.py --SIMG )

singularity exec -B ${SING_BIND} ${SIMG} python applycal.py \
--msin flagged_L686962_P41028.ms \
--h5 merged_addCS_selfcalcyle004_flagged_L686962_P41028.ms.copy.phaseup.h5 \
--colout CORRECTED_DATA

singularity exec -B ${SING_BIND} ${SIMG} python applycal.py \
--msin flagged_L769393_P41028.ms \
--h5 merged_addCS_selfcalcyle004_flagged_L769393_P41028.ms.copy.phaseup.h5 \
--colout CORRECTED_DATA

singularity exec -B ${SING_BIND} ${SIMG} python applycal.py \
--msin flagged_L798074_P41028.ms \
--h5 merged_addCS_selfcalcyle004_flagged_L798074_P41028.ms.copy.phaseup.h5 \
--colout CORRECTED_DATA

singularity exec -B ${SING_BIND} ${SIMG} python applycal.py \
--msin flagged_L816272_P41028.ms \
--h5 merged_addCS_selfcalcyle004_flagged_L816272_P41028.ms.copy.phaseup.h5 \
--colout CORRECTED_DATA

singularity exec -B ${SING_BIND} ${SIMG} wsclean \
-no-update-model-required \
-minuv-l 80.0 \
-size 2048 2048 \
-reorder \
-weight briggs -0.5 \
-clean-border 1 \
-parallel-reordering 4 \
-mgain 0.8 \
-data-column CORRECTED_DATA \
-padding 1.4 \
-join-channels \
-channels-out 6 \
-parallel-deconvolution 1024 \
-auto-mask 2.5 \
-auto-threshold 0.5 \
-multiscale \
-multiscale-scale-bias 0.7 \
-multiscale-max-scales 8 \
-fits-mask selfcal_010-MFS-image.fits.mask.fits \
-taper-gaussian 1.2arcsec \
-save-source-list \
-fit-spectral-pol 3 \
-pol i \
-baseline-averaging 4.793689962142628 \
-gridder wgridder \
-name test \
-scale 0.04arcsec \
-nmiter 12 \
-niter 30000 \
flagged_L686962_P41028.ms \
flagged_L769393_P41028.ms \
flagged_L798074_P41028.ms \
flagged_L816272_P41028.ms