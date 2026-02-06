#!/bin/bash
#SBATCH -t 1:00:00 -c 1

#/project/lofarvwf/Share/jdejong/output/EUCLID/edfn_centre/ddcal_dirs/EDFN_directions.csv
CSV=$1

SCRIPT_DIR=/home/lofarvwf-jdejong/scripts/lofar_vlbi_helpers/elais_200h
source /home/lofarvwf-jdejong/scripts/lofar_vlbi_helpers/elais_200h/other/chunk_csv.sh $CSV

# Loop through each CSV chunk file with an index
ENUMERATE=1
for CSV_CHUNK in chunk*.csv; do

  # Create run folder
  RUNFOLDER=chunk_${ENUMERATE}
  mkdir -p ${RUNFOLDER}
  mv ${CSV_CHUNK} ${RUNFOLDER}
  cd ${RUNFOLDER}

  # Submit the job with sbatch
  sbatch /home/lofarvwf-jdejong/scripts/lofar_vlbi_helpers/edfn/run_ddcal.sh $(realpath "${CSV_CHUNK}")
  cd ../

  # Increment the enumeration counter
  ((ENUMERATE++))
done
