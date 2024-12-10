#!/bin/bash
#SBATCH -c 1

#SINGULARITY SETTINGS
SING_BIND=$( python3 $HOME/parse_settings.py --BIND )
SIMG=$( python3 $HOME/parse_settings.py --SIMG )

singularity exec -B ${SING_BIND} ${SIMG} python /project/lofarvwf/Software/lofar_helpers/h5_merger.py -in testrotL769393.h5 -out tmp.h5 --add_cs --propagate_flags -ms /project/lofarvwf/Share/jdejong/output/ELAIS/ALL_L/ddcal/subbands/L769393_129MHz_P51570.ms
singularity exec -B ${SING_BIND} ${SIMG} python /project/lofarvwf/Software/lofar_helpers/h5_merger.py -in merged_L769393.h5 tmp.h5 -out merged_L769393_polrot.h5 --propagate_flags
singularity exec -B ${SING_BIND} ${SIMG} python /project/lofarvwf/Software/lofar_helpers/h5_merger.py -in testrotL798074.h5 -out tmp.h5 --add_cs --propagate_flags -ms /project/lofarvwf/Share/jdejong/output/ELAIS/ALL_L/ddcal/subbands/L798074_131MHz_P58902.ms
singularity exec -B ${SING_BIND} ${SIMG} python /project/lofarvwf/Software/lofar_helpers/h5_merger.py -in merged_L798074.h5 tmp.h5 -out merged_L798074_polrot.h5 --propagate_flags
singularity exec -B ${SING_BIND} ${SIMG} python /project/lofarvwf/Software/lofar_helpers/h5_merger.py -in testrotL816272.h5 -out tmp.h5 --add_cs --propagate_flags -ms /project/lofarvwf/Share/jdejong/output/ELAIS/ALL_L/ddcal/subbands/L816272_137MHz_P58902.ms
singularity exec -B ${SING_BIND} ${SIMG} python /project/lofarvwf/Software/lofar_helpers/h5_merger.py -in merged_L816272.h5 tmp.h5 -out merged_L816272_polrot.h5 --propagate_flags
cp merged_L686962.h5 merged_L686962_polrot.h5
rm tmp.h5
