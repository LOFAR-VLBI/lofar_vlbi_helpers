#!/bin/bash

FOLDER=/project/lofarvwf/Share/jdejong/output/ELAIS/ALL_L/ddcal/allselfcals

for P in P54450 P53334 P52238 P51372 P38451 P35307 P29603 P25722 P23167 P22135 P18996 P18696 P17565 P17010 P20075 P31553; do
  echo $P
  cp ${FOLDER}/${P}/selfcal_011-MFS-image.fits ${P}_selfcal_011_image.fits
  cp ${FOLDER}/${P}/selfcal_000-MFS-image.fits ${P}_selfcal_000_image.fits
  cp ${FOLDER}/${P}/selfcal_003-MFS-image.fits ${P}_selfcal_003_image.fits
done