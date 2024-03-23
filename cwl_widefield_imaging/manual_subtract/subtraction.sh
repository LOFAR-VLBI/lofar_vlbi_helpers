#!/bin/bash
#SBATCH -N 1 -c 24 --job-name=subtract --exclusive -t 13:00:00

echo "Job landed on $(hostname)"

  re="[0-9]{3}MHz"
  if [[ $MS =~ $re ]]; then SB=${BASH_REMATCH}; fi

MS=$1

SIMG_P2=/project/lofarvwf/Software/singularity/lofar_sksp_v3.3.4_x86-64_generic_avx512_ddfpublic.sif
SIMG=$( python3 $HOME/parse_settings.py --SIMG )
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

echo "SUBTRACT"
singularity exec -B $SING_BIND $SIMG_P2 python /project/lofarvwf/Software/lofar_facet_selfcal/sub-sources-outside-region.py \
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
--nofixsym \
--mslist mslist.txt

mv sub6asec* ../

echo "SUBTRACT END"