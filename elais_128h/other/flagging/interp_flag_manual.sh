#!/bin/bash
#SBATCH -c 12 --job-name=interp_flag

SIMG=$( python3 $HOME/parse_settings.py --SIMG )

# Get the file corresponding to this task
SB=$1
SB=$(realpath "$SB")

echo $SB

RUN_DIR=$TMPDIR/${LNUM}_${SLURM_ARRAY_TASK_ID}

mkdir -p ${RUN_DIR}

cp -r /project/lofarvwf/Share/jdejong/output/ELAIS/ALL_128h/6asec_sets/${LNUM}_6asec.ms ${RUN_DIR}
cp -r ${SB} ${RUN_DIR}
cp /project/lofarvwf/Software/lofar_helpers/ms_helpers/interpolate_flags.py ${RUN_DIR}
cp ${SIMG} ${RUN_DIR}

cd ${RUN_DIR}

singularity exec -B $PWD ${SIMG##*/} python interpolate_flags.py \
--skip_flagging \
--interpolate_from_ms ${LNUM}_6asec.ms \
${SB##*/}

# Check if the previous command was successful
if [ $? -eq 0 ]; then
    # If successful, execute the cp command
    cp -r ${SB##*/} ${SB}.new
else
    # If not successful, print an error message or handle the failure
    echo "Error: Previous command failed, no copy."
    exit 1
fi
