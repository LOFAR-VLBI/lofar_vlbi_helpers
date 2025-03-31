#!/bin/bash
#SBATCH -c 60
#SBATCH -p normal
#SBATCH --constraint=rome
#SBATCH --mail-type=FAIL,END
#SBATCH --mail-user=petley@strw.leidenuniv.nl
#SBATCH --output=ddf_%j.out
#SBATCH --error=ddf_%j.err
#SBATCH --time=2-00:00:00

#LINC TARGET FOLDER
START=$PWD
OUTPUT=$PWD/ddf_pol
RUNDIR=$TMPDIR/ddf_pol

mkdir -p $RUNDIR
mkdir -p $OUTPUT

SIMG=flocs_v5.1.0_znver2_znver2_test.sif

cd $OUTPUT

#wget https://lofar-webdav.grid.sara.nl/software/shub_mirror/tikk3r/lofar-grid-hpccloud/amd/${SIMG}
wget https://raw.githubusercontent.com/jwpetley/lofar_vlbi_helpers/refs/heads/main/elais_128h/ddf/pipeline_pol.cfg
wget https://public.spider.surfsara.nl/project/lofarvwf/jdejong/singularities/flocs_v5.1.0_znver2_znver2_test.sif

cp -r $START/target/L??????_LINC_target/results_LINC_target/results/*.ms .

singularity exec -B $PWD,$OUTPUT $SIMG make_mslists.py
singularity exec -B $PWD,$OUTPUT $SIMG pipeline.py pipeline.cfg


