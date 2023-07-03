#!/bin/bash
#SBATCH -c 10
#SBATCH --job-name=subtract
#SBATCH --array=0-150
#SBATCH --constraint=amd

#SINGULARITY SETTINGS
SING_BIND=$( python3 $HOME/parse_settings.py --BIND )
SIMG=$( python3 $HOME/parse_settings.py --SIMG )
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

mkdir -p facet_${SLURM_ARRAY_TASK_ID}
cp -r *.ms facet_${SLURM_ARRAY_TASK_ID}
cp poly_${SLURM_ARRAY_TASK_ID}.reg facet_${SLURM_ARRAY_TASK_ID}
cp facets_1.2.reg facet_${SLURM_ARRAY_TASK_ID}
cp merged_*.h5 facet_${SLURM_ARRAY_TASK_ID}
cd facet_${SLURM_ARRAY_TASK_ID}

PHASECENTER=$( cat ../polygon_point.csv | grep -m1 '1,' | cut -d',' -f4 )

for NIGHT in L686962 L769393 L798074 L816272; do

  mkdir -p ${NIGHT}
  mv *${NIGHT}*.ms ${NIGHT}
  cp merged_${NIGHT}.h5 ${NIGHT}

  cd ${NIGHT}

  for SB in *${NIGHT}*.ms; do
    sbatch ${SCRIPT_DIR}/subtract_sb.sh ${SB}

  cd ../



#<RUNFOLDER> (with output from split_in_facets.sh)
#     ├── facet_1
#     │-- facet_*
#     └── facet_N
#           ├── L??????
#           │-- L*
#           └── L??????
#                 ├── SB*120MHz*_folder
#                 │-- SB*_folder
#                 └── SB*164MHz*_folder
#                           └── sub_<RESOLUTION>*.ms    <------ those are what you want