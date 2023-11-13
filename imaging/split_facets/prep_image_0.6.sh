#!/bin/bash
#SBATCH -c 3
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=jurjendejong@strw.leidenuniv.nl
#SBATCH --job-name=imaging_facet
#SBATCH -p normal

FACET=facet_$1

cd ${FACET}
mkdir -p 06imaging
cd 06imaging
cp ../../poly_$1.reg .

for MS in ../imaging/*.ms; do
  echo $MS
  singularity exec -B /project/lofarvwf/Share/jdejong/,$PWD /project/lofarvwf/Software/singularity/lofar_sksp_v4.4.0_znver2_znver2_aocl4.sif \
  DP3 msin=$MS msout=avg0.6_${MS##*/} msin.datacolumn=DATA msout.storagemanager=dysco msout.writefullresflag=False steps=[avg] avg.type=averager avg.freqstep=2 avg.timestep=2
done

sbatch /home/lofarvwf-jdejong/scripts/lofar_vlbi_helpers/imaging/split_facets/make_image_0.6.sh $1
