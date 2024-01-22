#!/bin/bash
#SBATCH -c 45
#SBATCH -p infinite
#SBATCH -t 240:00:00
#SBATCH --mail-type=FAIL,END
#SBATCH --mail-user=jurjendejong@strw.leidenuniv.nl

#LINC TARGET FOLDER
TARGET_FOLDER=$1

DDF=/project/lofarvwf/Software/singularity/flocs_v4.5.0_znver2_znver2_aocl4_cuda.sif

mkdir -p ddf

cp pipeline.cfg ddf
cp $DDF ddf
cp -r $TARGET_FOLDER/*.ms ddf

cd ddf

singularity exec -B $PWD,/project/lofarvwf/Software $DDF make_mslists.py
singularity exec -B $PWD,/project/lofarvwf/Software,/project/lofarvwf,/project/lofarvwf/Public,/project/lofarvwf/Share $DDF pipeline.py pipeline.cfg
