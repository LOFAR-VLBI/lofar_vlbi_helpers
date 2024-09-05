#!/bin/bash
#SBATCH -c 5

FACET=$1

SIMG=$( python3 $HOME/parse_settings.py --SIMG )
SING_BIND=$( python3 $HOME/parse_settings.py --BIND )

cd /project/lofarvwf/Share/jdejong/output/ELAIS/ALL_L/imaging/split_facets2/facet_$FACET/1.2imaging

singularity exec -B $SING_BIND $SIMG python /project/lofarvwf/Software/lofar_helpers/h5_merger.py --add_ms_stations --ms concat_L68.ms -in selfcaloutput/merged_selfcalcyle009_concat_L68.ms.avg.h5 \
-out merged_L68.h5 --propagate_flags

singularity exec -B $SING_BIND $SIMG python /project/lofarvwf/Software/lofar_helpers/h5_merger.py --add_ms_stations --ms concat_L76.ms -in selfcaloutput/merged_selfcalcyle009_concat_L76.ms.avg.h5 \
-out merged_L76.h5 --propagate_flags

singularity exec -B $SING_BIND $SIMG python /project/lofarvwf/Software/lofar_helpers/h5_merger.py --add_ms_stations --ms concat_L79.ms -in selfcaloutput/merged_selfcalcyle009_concat_L79.ms.avg.h5 \
-out merged_L79.h5 --propagate_flags

singularity exec -B $SING_BIND $SIMG python /project/lofarvwf/Software/lofar_helpers/h5_merger.py --add_ms_stations --ms concat_L81.ms -in selfcaloutput/merged_selfcalcyle009_concat_L81.ms.avg.h5 \
-out merged_L81.h5 --propagate_flags

singularity exec -B $SING_BIND $SIMG python /project/lofarvwf/Software/lofar_helpers/ms_helpers/applycal.py \
--msin concat_L68.ms \
--msout concat_L68_sub.ms \
--h5 merged_L68.h5

singularity exec -B $SING_BIND $SIMG python /project/lofarvwf/Software/lofar_helpers/ms_helpers/applycal.py \
--msin concat_L76.ms \
--msout concat_L76_sub.ms \
--h5 merged_L76.h5

singularity exec -B $SING_BIND $SIMG python /project/lofarvwf/Software/lofar_helpers/ms_helpers/applycal.py \
--msin concat_L79.ms \
--msout concat_L79_sub.ms \
--h5 merged_L79.h5

singularity exec -B $SING_BIND $SIMG python /project/lofarvwf/Software/lofar_helpers/ms_helpers/applycal.py \
--msin concat_L81.ms \
--msout concat_L81_sub.ms \
--h5 merged_L81.h5

singularity exec -B $SING_BIND $SIMG python /home/lofarvwf-jdejong/scripts/lofar_vlbi_helpers/imaging/split_facets/make_image.py \
--resolution 1.2 \
--facet $FACET \
--facet_info /project/lofarvwf/Share/jdejong/output/ELAIS/ALL_L/imaging/split_facets2/polygon_info.csv \
--tmpdir

sbatch wsclean_facet${FACET}.cmd
