#!/bin/bash
#SBATCH -c 60
#SBATCH -p infinite
#SBATCH -t 240:00:00
##SBATCH --constraint=skylake

#LINC TARGET FOLDER
TARGET_FOLDER=$1

mkdir -p ddf

cp -r TARGET_FOLDER/*.ms ddf

cd ddf

apptainer pull https://public.spider.surfsara.nl/project/lofarvwf/jdejong/sing/ddf.sif

singularity exec -B $PWD ddf.sif make_mslists.py
singularity exec -B $PWD ddf.sif pipeline.py pipeline.cfg
