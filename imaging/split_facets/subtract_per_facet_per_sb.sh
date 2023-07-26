#!/bin/bash
#SBATCH -c 10
#SBATCH --job-name=subtract
#SBATCH --array=0-40%4
#SBATCH --constraint=amd
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=jurjendejong@strw.leidenuniv.nl

SCRIPT_DIR=/home/lofarvwf-jdejong/scripts/lofar_vlbi_helpers/imaging/split_facets
POLYREG=poly_${SLURM_ARRAY_TASK_ID}.reg
echo "COPY DATA"
mkdir -p facet_${SLURM_ARRAY_TASK_ID}
cp -r *.ms facet_${SLURM_ARRAY_TASK_ID}
cp ${POLYREG} facet_${SLURM_ARRAY_TASK_ID}
cp facets_1.2.reg facet_${SLURM_ARRAY_TASK_ID}
cp merged_*.h5 facet_${SLURM_ARRAY_TASK_ID}
cd facet_${SLURM_ARRAY_TASK_ID}

for NIGHT in L686962 L769393 L798074 L816272; do

  mkdir -p ${NIGHT}
  mv *${NIGHT}*.ms ${NIGHT}
  cp merged_${NIGHT}.h5 ${NIGHT}

  cd ${NIGHT}

  for SB in *${NIGHT}*.ms; do
    mv ../${SB} .
    sbatch ${SCRIPT_DIR}/subtract_sb.sh ${SB} ${NIGHT} ${POLYREG}

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