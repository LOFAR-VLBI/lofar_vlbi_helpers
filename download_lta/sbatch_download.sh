#!/bin/bash
#SBATCH -c 1
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=jurjendejong@strw.leidenuniv.nl

#1 --> html.txt
#2 --> path

#SINGULARITY SETTINGS
SIMG=$( python3 $HOME/parse_settings.py --SIMG )
BIND=$( python3 $HOME/parse_settings.py --BIND )

wget -ci $1 -P $2
python3 /home/lofarvwf-jdejong/scripts/lofar_vlbi_helpers/download_lta/untar.py --path $2
python3 /home/lofarvwf-jdejong/scripts/lofar_vlbi_helpers/extra_scripts/findmissingdata.py --path $2/Data
singularity exec -B ${BIND} ${SIMG} python ~/scripts/lofar_vlbi_helpers/download_lta/removebands.py --datafolder $2/Data