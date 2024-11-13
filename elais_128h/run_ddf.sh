#!/bin/bash
#SBATCH -c 31
#SBATCH -p normal
#SBATCH --mail-type=FAIL,END
#SBATCH --mail-user=jurjendejong@strw.leidenuniv.nl
#SBATCH --output=ddf_%j.out
#SBATCH --error=ddf_%j.err

#LINC TARGET FOLDER
TARGET_FOLDER=target/L??????_LINC_target/results_LINC_target/results
OUTPUT=$PWD/ddf
RUNDIR=$TMPDIR/ddf

mkdir -p $RUNDIR
mkdir -p $OUTPUT

SIMG=flocs_v4.5.0_znver2_znver2_aocl4_cuda.sif

cd $RUNDIR

wget https://lofar-webdav.grid.sara.nl/software/shub_mirror/tikk3r/lofar-grid-hpccloud/amd/${SIMG}
wget https://raw.githubusercontent.com/LOFAR-VLBI/lofar_vlbi_helpers/refs/heads/main/elais_128h/ddf/pipeline.cfg

cp -r $TARGET_FOLDER/*.ms .

singularity exec -B $PWD,$OUTPUT $SIMG make_mslists.py
singularity exec -B $PWD,$OUTPUT $SIMG pipeline.py pipeline.cfg
rm -rf *.ms

cp -r * $OUTPUT
