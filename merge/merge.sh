#!/bin/bash
#SBATCH -c 10

#SINGULARITY SETTINGS
SING_BIND=$( python3 $HOME/parse_settings.py --BIND )
SIMG=$( python3 $HOME/parse_settings.py --SIMG )

singularity exec -B ${SING_BIND} ${SIMG} python \
h5_merger.py -in /project/lofarvwf/Share/jdejong/output/ELAIS/ALL_L/dd_solutions/solutions/*L686962*.h5 \
-out merged_L686962.h5 \
--propagate_flags --no_stationflag_check

singularity exec -B ${SING_BIND} ${SIMG} python \
h5_merger.py -in /project/lofarvwf/Share/jdejong/output/ELAIS/ALL_L/dd_solutions/solutions/*L798074*.h5 \
-out merged_L798074.h5 \
--propagate_flags --no_stationflag_check

singularity exec -B ${SING_BIND} ${SIMG} python \
h5_merger.py -in /project/lofarvwf/Share/jdejong/output/ELAIS/ALL_L/dd_solutions/solutions/*L769393*.h5 \
-out merged_L769393.h5 \
--propagate_flags --no_stationflag_check

singularity exec -B ${SING_BIND} ${SIMG} python \
h5_merger.py -in /project/lofarvwf/Share/jdejong/output/ELAIS/ALL_L/dd_solutions/solutions/*L816272*.h5 \
-out merged_L816272.h5 \
--propagate_flags --no_stationflag_check

singularity exec -B ${SING_BIND} ${SIMG} python \
/project/lofarvwf/Software/lofar_helpers/h5_helpers/h5_flagger.py \
--h5 merged_L??????.h5 --ampflag
