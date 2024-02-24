#!/bin/bash
#SBATCH -N 1 -c 5 --job-name=split_directions

#Catalogue with sources --> FITS FILE WITH SOURCE CATALOGUE
CATALOG=$1

#L-number regex
re="L[0-9][0-9][0-9][0-9][0-9][0-9]"

#PATHS
SCRIPTS=/home/lofarvwf-jdejong/scripts/lofar_vlbi_helpers
PROJPATH=/project/lofarvwf/Share/jdejong/output/ELAIS
RESULTS_DIR=$PWD
#SINGULARITY
SIMG=$( python3 $HOME/parse_settings.py --SIMG )
SING_BIND=$( python3 $HOME/parse_settings.py --BIND )

echo "SINGULARITY IS $SIMG"

echo "Job landed on $(hostname)"

echo "-----------------STARTED SPLIT DIRECTIONS-----------------"

for MS in ${PROJPATH}/ALL_L/apply_delaycal/applycal_*.ms; do

  #Make calibrator parsets
  if [[ $MS =~ $re ]]; then LNUM=${BASH_REMATCH}; fi
  singularity exec -B $SING_BIND $SIMG python ${SCRIPTS}/split_directions/make_directions_parsets.py --catalog ${CATALOG} --prefix ${LNUM} --ms ${MS}
  echo "Made parsets for ${MS}"

done

#RUN PARSETS
PARSET_COUNT=$(ls *.parset | wc -l)
BATCHES=$(($PARSET_COUNT/5000))
for B in `seq ${BATCHES}`; do
  sbatch ${SCRIPTS}/split_directions/phaseshift_batch.sh $((${B} * 5000))
done

echo "-----------------FINISHED SPLIT DIRECTIONS-----------------"
