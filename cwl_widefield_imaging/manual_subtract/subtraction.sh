#!/bin/bash
#SBATCH -N 1 -c 31 --job-name=subtract -t 24:00:00

echo "Job landed on $(hostname)"

re="[0-9]{3}MHz"
if [[ $MS =~ $re ]]; then SB=${BASH_REMATCH}; fi

SIMG=/project/lofarvwf/Software/singularity/flocs_v5.1.0_znver2_znver2_test.sif
SING_BIND=$( python3 $HOME/parse_settings.py --BIND )

MS=$1

OUTPUT=$(realpath ../)
RUNDIR=$TMPDIR/subtract_${SLURM_JOB_ID}
H5=$(realpath ../../delaycal/DDF_merged.h5)

mkdir $RUNDIR
cp $SIMG $RUNDIR
cp -r * $RUNDIR
cp $H5 $RUNDIR

cd $RUNDIR

echo "Applycal"
singularity exec -B ${SING_BIND} ${SIMG} python \
/project/lofarvwf/Software/lofar_helpers/ms_helpers/applycal.py \
--msin ${MS} \
--colout DATA_DI_CORRECTED \
--h5 ${H5##*/}

mkdir SOLSDIR/${MS}
mv SOLSDIR/*${SB}*/* SOLSDIR/${MS}

singularity exec -B $SING_BIND ${SIMG##*/} python /home/lofarvwf-jdejong/scripts/lofar_vlbi_helpers/cwl_widefield_imaging/manual_subtract/fix_symlink.py

echo "SUBTRACT"
singularity exec -B $PWD ${SIMG##*/} sub-sources-outside-region.py \
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

mv sub6asec* $OUTPUT

echo "SUBTRACT END"