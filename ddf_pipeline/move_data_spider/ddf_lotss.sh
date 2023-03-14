#!/bin/bash
#SBATCH -N 1
#SBATCH -c 1

L=$1

cp -r /project/lofarvwf/Public/jdejong/ELAIS/${L}/ddf/* /project/lotss/Public/jdejong/ELAIS/${L}/ddf/
cp /project/lotss/Public/jdejong/scripts/ddfrun.sh /project/lotss/Public/jdejong/ELAIS/${L}/ddf/
cp /project/lotss/Public/jdejong/scripts/pipeline.cfg /project/lotss/Public/jdejong/ELAIS/${L}/ddf/
cd /project/lotss/Public/jdejong/ELAIS/${L}/ddf
#sbatch ./ddfrun.sh