#!/bin/bash
#SBATCH -N 1 -c 1

OBSERVATION=$1

#Move target
rclone --config=/home/lofarvwf-jdejong/macaroon/maca_lofarvwf.conf \
mkdir maca_lofarvwf:/disk/ELAIS/${OBSERVATION}/target
rclone --config=/home/lofarvwf-jdejong/macaroon/maca_lofarvwf.conf \
copy /project/lofarvwf/Share/jdejong/output/ELAIS/${OBSERVATION}/target/ \
maca_lofarvwf:/disk/ELAIS/${OBSERVATION}/target

#Move calibrator
rclone --config=/home/lofarvwf-jdejong/macaroon/maca_lofarvwf.conf \
mkdir maca_lofarvwf:/disk/ELAIS/${OBSERVATION}/calibrator
rclone --config=/home/lofarvwf-jdejong/macaroon/maca_lofarvwf.conf \
copy /project/lofarvwf/Share/jdejong/output/ELAIS/${OBSERVATION}/calibrator/ \
maca_lofarvwf:/disk/ELAIS/${OBSERVATION}/calibrator