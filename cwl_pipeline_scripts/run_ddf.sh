#!/bin/bash
#SBATCH -c 31
#SBATCH -p normal
#SBATCH --mail-type=FAIL,END
#SBATCH --mail-user=jurjendejong@strw.leidenuniv.nl
#SBATCH --exclude=wn-ca-10,wn-hb-01
#SBATCH --output=ddf_%j.out
#SBATCH --error=ddf_%j.err

#LINC TARGET FOLDER
TARGET_FOLDER=$1
mkdir $TMPDIR/ddf

wget https://lofar-webdav.grid.sara.nl/software/shub_mirror/tikk3r/lofar-grid-hpccloud/amd/flocs_v4.5.0_znver2_znver2_aocl4_cuda.sif
wget https://raw.githubusercontent.com/jurjen93/lofar_vlbi_helpers/main/ddf_pipeline/pipeline.cfg

SIMG=flocs_v4.5.0_znver2_znver2_aocl4_cuda.sif
OUTPUT=$PWD/ddf

mkdir -p $OUTPUT

cp pipeline.cfg $TMPDIR/ddf
cp $SIMG $TMPDIR/ddf
cp -r $TARGET_FOLDER/*.ms $TMPDIR/ddf

cd $TMPDIR/ddf

singularity exec -B $PWD,$OUTPUT $SIMG make_mslists.py
singularity exec -B $PWD,$OUTPUT $SIMG pipeline.py pipeline.cfg
rm -rf *.ms

cp -r * $OUTPUT
