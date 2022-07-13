#!/bin/bash
#SBATCH -c 1
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=jurjendejong@strw.leidenuniv.nl

#1 --> html.txt
#2 --> path

SIMG=/project/lofarvwf/Software/singularity/test_lofar_sksp_v3.3.4_x86-64_generic_avx512_ddf.sif

wget -ci $1 -P $2
python3 /home/lofarvwf-jdejong/scripts/prefactor_helpers/download_lta/untar.py --path $2
python3 /home/lofarvwf-jdejong/scripts/prefactor_helpers/helper_scripts/findmissingdata.py --path $2/Data
singularity exec -B $PWD,/project,/home/lofarvwf-jdejong/scripts ${SIMG} python ~/scripts/prefactor_helpers/download_lta/removebands.py --datafolder $2/Data