#!/bin/bash
#SBATCH -c 60
#SBATCH -p normal
#SBATCH --constraint=rome
#SBATCH --mail-type=FAIL,END
#SBATCH --mail-user=petley@strw.leidenuniv.nl
#SBATCH --output=ddf_%j.out
#SBATCH --error=ddf_%j.err

#LINC TARGET FOLDER
START=$PWD
OUTPUT=$PWD/ddf
RUNDIR=$TMPDIR/ddf

mkdir -p $RUNDIR
mkdir -p $OUTPUT

SIMG=flocs_v5.4.1_znver2_znver2.sif

cd $RUNDIR

wget https://lofar-webdav.grid.sara.nl/software/shub_mirror/tikk3r/lofar-grid-hpccloud/amd/${SIMG}
wget https://raw.githubusercontent.com/jwpetley/lofar_vlbi_helpers/refs/heads/main/elais_128h/ddf/pipeline.cfg

cp -r $START/target/L??????_LINC_target/results_LINC_target/results/*.ms .

singularity exec -B $PWD,$OUTPUT $SIMG make_mslists.py
singularity exec -B $PWD,$OUTPUT $SIMG pipeline.py pipeline.cfg
rm -rf *.ms

cp -r * $OUTPUT

cd $OUTPUT

#FIX SYMLINKS
# Define the old and new base paths
old_base="/tmp/ddf"
re="L[0-9][0-9][0-9][0-9][0-9][0-9]"
re_subband="([^.]+)"
if [[ $PWD =~ $re ]]; then LNUM=${BASH_REMATCH}; fi

# Loop over all symlinks in the current directory
for symlink in SOLSDIR/L*.ms/*.npz; do
    if [ -L "$symlink" ]; then
        target=$(readlink "$symlink")
        if [[ "$target" == $old_base* ]]; then
            new_base="/project/wfedfn/Share/jpetley/output/EDFN/${LNUM}/${LNUM}/ddf/"
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
