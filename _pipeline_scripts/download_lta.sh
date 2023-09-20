#!/bin/bash
#SBATCH -c 1
#SBATCH --array=0-1
#SBATCH --output=download_lta_%j.out
#SBATCH --error=download_lta_%j.err

#1 --> html_calibrator.txt
#2 --> html_target.txt

#if [ $# -eq 0 ]
#  then
#    echo "No arguments supplied"
#    echo "Please run script as [ download_lta.sh html_calibrator.txt html_target.txt ]"
#    exit 0
#fi

#GET ORIGINAL SCRIPT DIRECTORY
if [ -n "${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}" ] ; then
SCRIPT=$(scontrol show job "${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}" | awk -F= '/Command=/{print $2}')
SCRIPT_DIR=$( echo ${SCRIPT%/*} )
else
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
fi

#SINGULARITY SETTINGS
SIMG=$( python3 $SCRIPT_DIR/settings/parse_settings.py --SIMG )
BIND=$( python3 $SCRIPT_DIR/settings/parse_settings.py --BIND )

LNUM=$( grep -Po 'L[0-9][0-9][0-9][0-9][0-9][0-9]' $2 | head -n 1 )
mkdir -p $LNUM
cd $LNUM

#CALIBRATOR
if $SLURM_ARRAY_TASK_ID=0; then
  LNUM_CAL=$( grep -Po 'L[0-9][0-9][0-9][0-9][0-9][0-9]' $1 | head -n 1 )
  echo "DOWNLOAD DATA FOR $LNUM_CAL"
  mkdir -p calibrator
  wget -ci $1 -P calibrator
  python3 $SCRIPT_DIR/download_scripts/untar.py --path calibrator
  python3 $SCRIPT_DIR/download_scripts/findmissingdata.py --path calibrator/Data
  singularity exec -B ${BIND} ${SIMG} python $SCRIPT_DIR/download_scripts/removebands.py --datafolder calibrator/Data
fi

#TARGET
if $SLURM_ARRAY_TASK_ID=1; then
  echo "DOWNLOAD DATA FOR $LNUM"
  mkdir -p target
  wget -ci $1 -P target
  python3 $SCRIPT_DIR/download_scripts/untar.py --path target
  python3 $SCRIPT_DIR/download_scripts/findmissingdata.py --path target/Data
  singularity exec -B ${BIND} ${SIMG} python $SCRIPT_DIR/download_scripts/removebands.py --datafolder target/Data
fi

#TODO: RETURN STATISTICS AND VALIDATION
