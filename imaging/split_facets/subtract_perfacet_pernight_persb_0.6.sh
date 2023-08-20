#!/bin/bash
#SBATCH -c 20
#SBATCH --job-name=subtract
#SBATCH --array=0-24
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=jurjendejong@strw.leidenuniv.nl

FACETID=$1
NIGHT=$2

SING_BIND=$( python3 $HOME/parse_settings.py --BIND )
SIMG=$( python3 $HOME/parse_settings.py --SIMG )

MAINFOLDER=${PWD}
IMAGINGFOLDER=${MAINFOLDER}/facet_${FACETID}/imaging
OUTPUTFOLDER=${MAINFOLDER}/facet_${FACETID}/${NIGHT}
LOGFOLDER=${OUTPUTFOLDER}/SB_${SLURM_ARRAY_TASK_ID}
RUNFOLDER=${TMPDIR}/facet_${FACETID}/${NIGHT}_${SLURM_ARRAY_TASK_ID}

mkdir -p ${MAINFOLDER}/facet_${FACETID}
mkdir -p ${IMAGINGFOLDER}
mkdir -p ${OUTPUTFOLDER}
mkdir -p ${RUNFOLDER}

pattern="/project/lofarvwf/Share/jdejong/output/ELAIS/ALL_L/apply_delaycal/apply*${NIGHT}*.ms"
MS_FILES=( $pattern )
SB=${MS_FILES[${SLURM_ARRAY_TASK_ID}]}

cp -r ${SB} ${RUNFOLDER}
cp poly_${FACETID}.reg ${RUNFOLDER}
cp facets_0.6.reg ${RUNFOLDER}
cp merged_${NIGHT}_polrot.h5 ${RUNFOLDER}
cp polygon_info.csv ${RUNFOLDER}
cp $SIMG ${RUNFOLDER}
cp /project/lofarvwf/Share/jdejong/output/ELAIS/ALL_L/imaging/modelimages_0.6/${NIGHT}/*.fits ${RUNFOLDER}

cd ${RUNFOLDER}

#subtract ms with wsclean for each facet
singularity exec -B $PWD ${SIMG##*/} python \
/home/lofarvwf-jdejong/scripts/lofar_helpers/subtract/subtract_with_wsclean.py \
--mslist ${SB##*/} \
--region poly_${FACETID}.reg \
--model_image_folder $PWD \
--facets_predict facets_0.6.reg \
--h5parm_predict merged_${NIGHT}_polrot.h5 \
--applycal \
--applybeam \
--forwidefield

mv sub*${NIGHT}*.ms ${IMAGINGFOLDER}

mkdir -p ${LOGFOLDER}
ls -1d * > ${LOGFOLDER}/sb_${SLURM_ARRAY_TASK_ID}.txt
mv *.log ${LOGFOLDER} # copy log files
mv *.txt ${LOGFOLDER} # copy text files
mv *.cmd ${LOGFOLDER} # copy command files

#ONLY FOR TESTING
#mv *-pb.fits ${LOGFOLDER}
#mv applycal*.ms ${LOGFOLDER}
#mv *.h5 ${LOGFOLDER}
#mv *.reg ${LOGFOLDER}
#mv polygon_info.csv ${LOGFOLDER}