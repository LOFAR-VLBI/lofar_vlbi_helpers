#!/bin/bash
#SBATCH -N 1 -c 24 --job-name=subtract -t 30:00:00

echo "Job landed on $(hostname)"

re="[0-9]{3}MHz"
if [[ $MS =~ $re ]]; then SB=${BASH_REMATCH}; fi

MS=$1

SIMG=/project/lofarvwf/Software/singularity/flocs_v5.1.0_znver2_znver2_test.sif
SING_BIND=$( python3 $HOME/parse_settings.py --BIND )
echo "SINGULARITY IS $SIMG"

echo "Applycal"
singularity exec -B ${SING_BIND} ${SIMG} python \
/project/lofarvwf/Software/lofar_helpers/ms_helpers/applycal.py \
--msin ${MS} \
--colout DATA_DI_CORRECTED \
--h5 ../../delaycal/DDF_merged.h5

mkdir SOLSDIR/${MS}
mv SOLSDIR/*${SB}*/* SOLSDIR/${MS}

singularity exec -B $SING_BIND $SIMG python /home/lofarvwf-jdejong/scripts/lofar_vlbi_helpers/cwl_widefield_imaging/manual_subtract/fix_symlink.py

echo "SUBTRACT"
singularity exec -B $SING_BIND $SIMG sub-sources-outside-region.py \
--boxfile boxfile.reg \
--column DATA_DI_CORRECTED \
--freqavg 1 \
--timeavg 1 \
--ncpu 24 \
--prefixname sub6asec \
--noconcat \
--keeplongbaselines \
--nophaseshift \
--chunkhours 0.5 \
--onlyuseweightspectrum \
--mslist mslist.txt

mv sub6asec* ../

echo "SUBTRACT END"