#!/bin/bash

STRW_FOLDER=$1 #/net/rijn5/data2/jurjdendejong/ELAIS/L816272_8
OUTPUT_FOLDER=$2

cd /home/jurjen/Documents/elais/delaycaltest/
mkdir -p ${OUTPUT_FOLDER}

scp -r jurjendejong@oolderplas.strw.leidenuniv.nl:${STRW_FOLDER}/plotlosotoL816272_120_168MHz_averaged.ms.smallphaseupset.avg /home/jurjen/Documents/elais/delaycaltest/${OUTPUT_FOLDER}
scp jurjendejong@oolderplas.strw.leidenuniv.nl:${STRW_FOLDER}/selfcal_${OUTPUT_FOLDER}_LBCS_0.png /home/jurjen/Documents/elais/delaycaltest/${OUTPUT_FOLDER}
scp jurjendejong@oolderplas.strw.leidenuniv.nl:${STRW_FOLDER}/selfcal_${OUTPUT_FOLDER}_LBCS_1.png /home/jurjen/Documents/elais/delaycaltest/${OUTPUT_FOLDER}
scp jurjendejong@oolderplas.strw.leidenuniv.nl:${STRW_FOLDER}/selfcal_${OUTPUT_FOLDER}_LBCS_2.png /home/jurjen/Documents/elais/delaycaltest/${OUTPUT_FOLDER}
scp jurjendejong@oolderplas.strw.leidenuniv.nl:${STRW_FOLDER}/selfcal_${OUTPUT_FOLDER}_LBCS_3.png /home/jurjen/Documents/elais/delaycaltest/${OUTPUT_FOLDER}
scp jurjendejong@oolderplas.strw.leidenuniv.nl:${STRW_FOLDER}/selfcal_${OUTPUT_FOLDER}_LBCS_4.png /home/jurjen/Documents/elais/delaycaltest/${OUTPUT_FOLDER}

#scp jurjendejong@oolderplas.strw.leidenuniv.nl:${STRW_FOLDER}/selfcal_round6_LBCS_0.png /home/jurjen/Documents/elais/delaycaltest/${OUTPUT_FOLDER}
#scp jurjendejong@oolderplas.strw.leidenuniv.nl:${STRW_FOLDER}/selfcal_round6_LBCS_1.png /home/jurjen/Documents/elais/delaycaltest/${OUTPUT_FOLDER}
#scp jurjendejong@oolderplas.strw.leidenuniv.nl:${STRW_FOLDER}/selfcal_round6_LBCS_2.png /home/jurjen/Documents/elais/delaycaltest/${OUTPUT_FOLDER}
#scp jurjendejong@oolderplas.strw.leidenuniv.nl:${STRW_FOLDER}/selfcal_round6_LBCS_3.png /home/jurjen/Documents/elais/delaycaltest/${OUTPUT_FOLDER}
#scp jurjendejong@oolderplas.strw.leidenuniv.nl:${STRW_FOLDER}/selfcal_round6_LBCS_4.png /home/jurjen/Documents/elais/delaycaltest/${OUTPUT_FOLDER}