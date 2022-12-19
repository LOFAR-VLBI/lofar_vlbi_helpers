#!/bin/bash

#INPUT --> L-NUMBER OF TARGET
LNUM=$1

SCRIPT_FOLDER=.

mkdir ${LNUM}
cd ${LNUM}

###############
###PREFACTOR###
###############

mkdir -p calibrator
mkdir -p calibrator/Data
mkdir -p target
mkdir -p target/Data

#TODO: html text has to be found somewhere
cd ${LNUM}
sbatch ${SCRIPT_FOLDER}/download_lta/sbatch_download.sh html_calibrator.txt calibrator
sbatch ${SCRIPT_FOLDER}/download_lta/sbatch_download.sh html_target.txt target

cd ${LNUM}
cd calibrator
sbatch ${SCRIPT_FODLER}/prefactor_pipeline/run_PFC.sh $PWD
#TODO: verify calibrator is finished

cd ${LNUM}
cd target
sbatch ${SCRIPT_FOLDER}/prefactor_pipeline/run_PFT.sh $PWD ../calibrator
#TODO: verify target is finished

#########
###DDF###
#########

#TODO: use ${SCRIPT_FOLDER}/ddf_pipeline/ddfrun.sh --> needs specific software

###################
###VLBI-delaycal###
###################

cd ${LNUM}
mkdir delaycal
cd delaycal
sbatch ${SCRIPT_FOLDER}/lofar-vlbi-setup/run_DC.sh
#TODO: check if succesfully finished

##############
###SUBTRACT###
##############

cd ${LNUM}
mkdir subtract
cd subtract
sbatch ${SCRIPT_FOLDER}/subtract_lotss/subtract_main.sh
#TODO: verify if subtract is completed
cd subtract_lotss
sbatch ${SCRIPT_FOLDER}/subtract_lotss/concat.sh
#TODO: verify if concat is succesfull

##################
###DELAYSELFCAL###
##################

cd ${LNUM}
mkdir delayselfcal
cd delayselfcal
sbatch ${SCRIPT_FOLDER}/delay_facetselfcal_surf.sh
#TODO: verify delayselfcal went well

cd ${LNUM}
mkdir apply_delaycal
cd apply_delaycal
sbatch ${SCRIPT_FOLDER}/applycal/applycal_multiple.sh ../delayselfcal/merged_skyselfcalcyle000_${LNUM}_120_168MHz_averaged.ms.avg.h5
#TODO: make general input for h5 (currently not general)
#TODO: verify applycal output

#########################
###OPTIONAL:DI_IMAGING###
#########################

cd ${LNUM}
mkdir imaging
mkdir DI_1asec # 1 arcsec image
cd DI_1asec
sbatch ${SCRIPT_FOLDER}/imaging/DI_image/wsclean_DI_1asec_1secaverage.sh

#############
###DD_CAL####
#############

#find directions
cd ${LNUM}
mkdir ddcal
cd ddcal
ls -1d $LNUM > l_list.txt
#TODO: download catalogue
sbatch ${SCRIPT_FOLDER}/split_directions/split_directions.sh l_list.txt <CATALOGUE>
#TODO: verify splitting correctly
sbatch ${SCRIPT_FOLDER}/split_directions/concat_dirs.sh
#TODO: verify concat correctly

#calibrate directions
mkdir all_directions
mv ${LNUM}*.ms all_directions
mkdir selfcals
cd selfcals
sbatch ${SCRIPT_FOLDER}/ddcal/run_selfcal.sh
#TODO: verify if correct

#direction selection
python ${SCRIPT_FOLDER}/ddcal/dir_selection_zoe.py --dirs $PWD
#TODO: needs singularity wrapped and improvement of dir selection

################
###DD_IMAGING###
################

cd ${LNUM}
mkdir -p imaging #possibly already made for DI optional part
cd imaging
mkdir DD_0.3asec
mkdir DD_1asec
cd DD_0.3asec
sbatch ${SCRIPT_FOLDER}/imaging/DD_image/wsclean_DD_0.3asec.sh
cd ../DD_1asec ${SCRIPT_FOLDER}/imaging/DD_image/wsclean_DD_1asec.sh
#TODO: verify if imaging is correct

