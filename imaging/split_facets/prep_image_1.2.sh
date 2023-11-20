#!/bin/bash
#SBATCH -c 3
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=jurjendejong@strw.leidenuniv.nl
#SBATCH --job-name=imaging_facet
#SBATCH -p normal

FACET=facet_$1

cd ${FACET}
mkdir -p 1.2imaging
cd 1.2imaging
cp ../../poly_$1.reg .

for MS in ../imaging/*.ms; do
  echo $MS
  singularity exec -B /project/lofarvwf/Share/jdejong/,$PWD /project/lofarvwf/Software/singularity/lofar_sksp_v4.4.0_znver2_znver2_aocl4.sif \
  DP3 msin=$MS msout=avg1.2_${MS##*/} msin.datacolumn=DATA msout.storagemanager=dysco msout.writefullresflag=False steps=[avg] avg.type=averager avg.freqstep=4 avg.timestep=4
done

#sbatch /home/lofarvwf-jdejong/scripts/lofar_vlbi_helpers/imaging/split_facets/make_image_1.2.sh $1

singularity exec -B /project/lofarvwf/Share/jdejong/,$PWD /project/lofarvwf/Software/singularity/lofar_sksp_v4.4.0_znver2_znver2_aocl4.sif \
python /home/lofarvwf-jdejong/scripts/lofar_vlbi_helpers/imaging/split_facets/make_image.py --resolution 1.2 --facet $1 --facet_info ../../polygon_info.csv --tmpdir
