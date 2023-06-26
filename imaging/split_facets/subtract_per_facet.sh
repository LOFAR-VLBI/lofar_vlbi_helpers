#!/bin/bash
#SBATCH -c 10
#SBATCH --job-name=subtract
#SBATCH --array=0-XXXX
#SBATCH --constraint=amd

#SINGULARITY SETTINGS
SING_BIND=$( python3 $HOME/parse_settings.py --BIND )
SIMG=$( python3 $HOME/parse_settings.py --SIMG )

mkdir -p facet_${SLURM_ARRAY_TASK_ID}
cp -r avg*.ms facet_${SLURM_ARRAY_TASK_ID}
cp poly_${SLURM_ARRAY_TASK_ID}.reg facet_${SLURM_ARRAY_TASK_ID}
cp facets.reg facet_${SLURM_ARRAY_TASK_ID}
cp merged_*.h5 facet_${SLURM_ARRAY_TASK_ID}
cd facet_${SLURM_ARRAY_TASK_ID}

PHASECENTER=$( cat ../polygon_point.csv | grep -m1 '1,' | cut -d',' -f4 )

for NIGHT in L686962 L769393 L798074 L816272; do

  mkdir -p ${NIGHT}
  mv avg*${NIGHT} ${NIGHT}
  cp merged_${NIGHT}.h5 ${NIGHT}

  cd ${NIGHT}

  #subtract ms with wsclean for each facet
  singularity exec -B ${SING_BIND} ${SIMG} python \
  /home/lofarvwf-jdejong/scripts/lofar_helpers/subtract_with_wsclean/subtract_with_wsclean.py \
  --mslist avg*.ms \
  --region ../poly_${SLURM_ARRAY_TASK_ID}.reg \
  --model_image_folder .. \
  --facet_region ../facets.reg \
  --h5parm_predict merged_${NIGHT}.h5 \
  --forwidefield

  rm -rf avg*.ms

  cd ../

mv L??????/sub*.ms .

sbatch /home/lofarvwf-jdejong/scripts/lofar_vlbi_helpers/imaging/split_facets/make_image_1.2.sh

#apply solutions to new subtracted MS
#make image