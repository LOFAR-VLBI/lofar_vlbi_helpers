#!/bin/bash
#SBATCH -c 1
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=jurjendejong@strw.leidenuniv.nl

#1 --> html.txt
#2 --> path

wget -ci $1 -P $2
python3 /home/lofarvwf-jdejong/scripts/prefactor_helpers/download_lta/untar.py --path $2
python3 /home/lofarvwf-jdejong/scripts/prefactor_helpers/helper_scripts/findmissingdata.py --path $2/Data
python3 ~/scripts/prefactor_helpers/download_lta/removebands.py --datafolder $2/Data