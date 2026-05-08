#!/bin/bash
#SBATCH -c 32
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=jurjendejong@strw.leidenuniv.nl

wget https://public.spider.surfsara.nl/project/lofarvwf/fsweijen/containers/flocs_v6.0.0_znver2_znver2.sif

singularity exec -B $PWD,$TMPDIR flocs_v6.0.0_znver2_znver2.sif \
sva --dysco_bitrate 6 --tmp $TMPDIR facet*.ms
