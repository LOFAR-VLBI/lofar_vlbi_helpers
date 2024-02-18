#!/bin/bash
#SBATCH -c 37
#SBATCH -p normal
#SBATCH --mail-type=FAIL,END
#SBATCH --mail-user=jurjendejong@strw.leidenuniv.nl
#SBATCH --exclude=wn-ca-10,wn-hb-01

#LINC TARGET FOLDER
TARGET_FOLDER=$1
mkdir $TMPDIR/ddf

DDF=/project/lofarvwf/Software/singularity/flocs_v4.5.0_znver2_znver2_aocl4_cuda.sif
OUTPUT=$PWD/ddf

mkdir -p $OUTPUT

cp /project/lofarvwf/Share/jdejong/output/ELAIS/pipeline.cfg $TMPDIR/ddf
cp $DDF $TMPDIR/ddf
cp -r $TARGET_FOLDER/*.ms $TMPDIR/ddf
cp $DDF $TMPDIR/ddf

cd $TMPDIR/ddf

singularity exec -B $PWD,$OUTPUT flocs_v4.5.0_znver2_znver2_aocl4_cuda.sif make_mslists.py
singularity exec -B $PWD,$OUTPUT flocs_v4.5.0_znver2_znver2_aocl4_cuda.sif pipeline.py pipeline.cfg
rm -rf *.ms

cp -r * $OUTPUT
