#!/bin/bash
#SBATCH -c 31
#SBATCH -p normal
#SBATCH --mail-type=FAIL,END
#SBATCH --mail-user=jurjendejong@strw.leidenuniv.nl
#SBATCH --exclude=wn-ca-10,wn-hb-01
#SBATCH --output=ddf_%j.out
#SBATCH --error=ddf_%j.err

#LINC TARGET FOLDER
TARGET_FOLDER=$(realpath $1)
OUTPUT=$PWD/ddf
RUNDIR=$TMPDIR/ddf

mkdir -p $RUNDIR
mkdir -p $OUTPUT

SIMG=flocs_v4.5.0_znver2_znver2_aocl4_cuda.sif

cd $RUNDIR

wget https://lofar-webdav.grid.sara.nl/software/shub_mirror/tikk3r/lofar-grid-hpccloud/amd/${SIMG}
wget https://raw.githubusercontent.com/jurjen93/lofar_vlbi_helpers/main/cwl_widefield_imaging/ddf/pipeline.cfg

cp -r $TARGET_FOLDER/*.ms .

singularity exec -B $PWD,$OUTPUT $SIMG make_mslists.py
singularity exec -B $PWD,$OUTPUT $SIMG pipeline.py pipeline.cfg
rm -rf *.ms

cp -r * $OUTPUT
