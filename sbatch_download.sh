#!/bin/bash
#SBATCH -c 1
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=jurjendejong@strw.leidenuniv.nl
#SBATCH --array=0-1

#echo "HI"
#N=$(sed -n '$=' L769389/surls_links.txt)-1
#echo ${N}
#for ((i=0;i<=${N};i++)); do
#    echo $i
#done

python3 download_lta.py --input $1 --to_path $2 --parallel --n ${SLURM_ARRAY_TASK_ID}