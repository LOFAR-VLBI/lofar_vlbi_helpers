#!/bin/bash
#SBATCH -c 15
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=jurjendejong@strw.leidenuniv.nl
#SBATCH --job-name=imaging_facet

#IMSIZE=$1

#SINGULARITY SETTINGS
SING_BIND=$( python3 $HOME/parse_settings.py --BIND )
SIMG=$( python3 $HOME/parse_settings.py --SIMG )

#K=$(( ${SLURM_ARRAY_TASK_ID}+2 )) #TODO: Change slurm_array_task_id
#AVG=$(cat polygon_info.csv | head -n $K | tail -n 1 | cut -d',' -f7)
#IMSIZE=$(( 22500/${AVG} )) #TODO: Currently fails

echo "----------START WSCLEAN----------"

singularity exec -B ${SING_BIND} ${SIMG} \
wsclean \
-gridder wgridder \
-no-update-model-required \
-minuv-l 80.0 \
-size 20000 20000 \
-weighting-rank-filter 3 \
-reorder \
-weight briggs -0.5 \
-parallel-reordering 6 \
-mgain 0.65 \
-data-column DATA \
-auto-mask 3 \
-auto-threshold 1.0 \
-pol i \
-name 0.3asec_I \
-scale 0.07arcsec \
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
-parallel-gridding 6 \
-facet-beam-update 600 \
-use-differential-lofar-beam \
sub*.ms

echo "----------FINISHED WSCLEAN----------"
