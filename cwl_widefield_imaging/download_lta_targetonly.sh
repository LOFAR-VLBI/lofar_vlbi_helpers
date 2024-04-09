#!/bin/bash
#SBATCH -c 1
#SBATCH --output=download_lta.out
#SBATCH --error=download_lta.err

#1 --> html_target.txt

TARHTML=$1

if [ -n "$TARHTML" ]; then
  echo "You gave $TARHTML as target html list"
  TARDAT=$( realpath $TARHTML )
else
  echo "No target html list provided"
  echo "Please run script as [ download_lta.sh html_calibrator.txt html_target.txt ]"
  exit 0
fi


#GET SCRIPT RUN DIRECTORY
if [ -n "${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}" ] ; then
SCRIPT=$(scontrol show job "${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}" | awk -F= '/Command=/{print $TARHTML}')
export SCRIPT_DIR=$( echo ${SCRIPT%/*} )
else
export SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
fi

#SINGULARITY SETTINGS
SIMG=$( python3 $SCRIPT_DIR/settings/parse_settings.py --SIMG )
BIND=$( python3 $SCRIPT_DIR/settings/parse_settings.py --BIND )

LNUM=$( grep -Po 'L\d+' $TARDAT | head -n 1 )
mkdir -p $LNUM
cd $LNUM

echo "DOWNLOAD DATA FOR TARGET $LNUM"
TYPE=target
TARS=$TARDAT

# make data folder
mkdir -p $TYPE/data
cd $TYPE/data

# download data
wget -ci $TARS

# untar data
for TAR in *SB*.tar*; do
  mv $TAR tmp.tar
  tar -xvf tmp.tar
  rm tmp.tar
done

# find missing data
python3 $SCRIPT_DIR/download_scripts/findmissingdata.py

# remove bands above 168 MHz
singularity exec -B ${BIND} ${SIMG} python $SCRIPT_DIR/download_scripts/removebands.py --freqcut 168
