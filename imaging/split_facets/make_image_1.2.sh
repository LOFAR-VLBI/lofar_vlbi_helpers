#!/bin/bash
#SBATCH -c 23
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=jurjendejong@strw.leidenuniv.nl
#SBATCH --constraint=intel
#SBATCH --job-name=DI_1_imaging

IMSIZE=$1

#SINGULARITY SETTINGS
SING_BIND=$( python3 $HOME/parse_settings.py --BIND )
SIMG=$( python3 $HOME/parse_settings.py --SIMG )

K=$(( ${SLURM_ARRAY_TASK_ID}+2 )) #TODO: Change slurm_array_task_id
AVG=$(cat polygon_info.csv | head -n $K | tail -n 1 | cut -d',' -f7)
IMSIZE=$(( 22500/${AVG} )) #TODO: Currently fails

echo "----------START WSCLEAN----------"

singularity exec -B ${SING_BIND} ${SIMG} \
wsclean \
-use-idg \
-update-model-required \
-minuv-l 80.0 \
-size ${IMSIZE} ${IMSIZE} \
-weighting-rank-filter 3 \
-reorder \
-weight briggs -1.5 \
-parallel-reordering 6 \
-mgain 0.65 \
-data-column SUBTRACT_DATA \
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
-nmiter 9 \
-channels-out 6 \
-join-channels \
-fit-spectral-pol 3 \
-deconvolution-channels 3 \
-grid-with-beam \
-use-differential-lofar-beam \
sub*.ms

echo "----------FINISHED WSCLEAN----------"
