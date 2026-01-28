#!/bin/bash
#SBATCH -c 48
#SBATCH -p normal
#SBATCH --mail-type=FAIL,END
#SBATCH --mail-user=jurjendejong@strw.leidenuniv.nl
#SBATCH --output=ddf_%j.out
#SBATCH --error=ddf_%j.err

#LINC TARGET FOLDER
START=$PWD
OUTPUT=$PWD/ddf
RUNDIR=$TMPDIR/ddf

SCRIPT_DIR=/home/lofarvwf-jdejong/scripts/lofar_vlbi_helpers/edfn
source $SCRIPT_DIR/setup.sh --no-git --no-sing

mkdir -p $RUNDIR
mkdir -p $OUTPUT

SIMG=flocs_v4.5.0_znver2_znver2_aocl4_cuda.sif

cd $RUNDIR

wget https://lofar-webdav.grid.sara.nl/software/shub_mirror/tikk3r/lofar-grid-hpccloud/amd/${SIMG}
wget https://raw.githubusercontent.com/LOFAR-VLBI/lofar_vlbi_helpers/refs/heads/main/elais_200h/ddf/pipeline.cfg


for MS in $START/target/LINC_target_*/results_LINC_target/results/*_pre-cal.ms; do
  echo ${MS}
  singularity exec -B $PWD,$OUTPUT,$START $SING_IMG \
  DP3 \
  msin=${MS} \
  msout=$(basename ${MS}) \
  steps=[] \
  msout.storagemanager='dysco' \
  msout.uvwcompression=False \
  msout.antennacompression=False \
  msout.scalarflags=False
done

singularity exec -B $PWD,$OUTPUT $SIMG make_mslists.py
singularity exec -B $PWD,$OUTPUT $SIMG pipeline.py pipeline.cfg
rm -rf *.ms

cp -r * $OUTPUT

cd $OUTPUT

#FIX SYMLINKS
for symlink in SOLSDIR/L*.ms/*.npz; do
    if [ -L "$symlink" ]; then
        target=$(readlink "$symlink")
        old_base=$(dirname "$target")
        if [[ "$target" == $old_base* ]]; then
            new_base="${PWD}"
            new_target="${target/$old_base/$new_base}"
            echo "Updating symlink: $symlink"
            rm "$symlink"
            ln -s "$new_target" "$symlink"
            echo "Symlink updated: $symlink -> $new_target"
        fi
    else
        echo "Skipping $symlink: Not a valid symlink"
    fi
done

cd SOLSDIR
rename _pre-cal.ms .dp3concat *_pre-cal.ms
