#!/bin/bash
#SBATCH -N 1 -c 4 --job-name=applycal --array=0-24

#INPUT MS and H5
H5=$1
P=$2

SIMG=$( python3 $HOME/parse_settings.py --SIMG )
BIND=$( python3 $HOME/parse_settings.py --BIND )
echo "SINGULARITY IS $SIMG"

pattern="/project/lofarvwf/Share/jdejong/output/ELAIS/ALL_L/apply_delaycal/*${P}*.ms"
MS_FILES=( $pattern )
MS=${MS_FILES[${SLURM_ARRAY_TASK_ID}]}

singularity exec -B $BIND $SIMG \
python /home/lofarvwf-jdejong/scripts/lofar_vlbi_helpers/applycal/applycal.py \
--msin $MS \
--h5 ${H5} \
--msout applycal_${MS##*/}
