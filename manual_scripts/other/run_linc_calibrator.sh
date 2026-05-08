#!/bin/bash
#SBATCH -c 16
#SBATCH --output=linc_%j.out
#SBATCH --error=linc_%j.err
#SBATCH -t 12:00:00

FLOCSRUNNERS=/project/lofarvwf/Software/flocs/runners

STARTDIR=$PWD

#SINGULARITY SETTINGS
SING_BIND=$( python3 $HOME/parse_settings.py --BIND )
SIMG=/project/lofarvwf/Software/singularity/flocs_v5.2.0_znver2_znver2.sif


cd calibrator

singularity exec -B ${SING_BIND} ${SIMG} $FLOCSRUNNERS/run_LINC_calibrator_HBA.sh -d $STARTDIR/calibrator/data -l /project/lofarvwf/Software/LINC
