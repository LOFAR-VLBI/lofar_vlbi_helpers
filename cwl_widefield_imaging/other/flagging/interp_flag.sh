#!/bin/bash
#SBATCH -c 20 --job-name=interp_flag

SIMG=$( python3 $HOME/parse_settings.py --SIMG )
SING_BIND=$( python3 $HOME/parse_settings.py --BIND )

SB=$1
LNUM=$2

cp -r $SB $SB.backup

singularity exec -B $SING_BIND $SIMG python /project/lofarvwf/Software/lofar_helpers/ms_helpers/interpolate_flags.py \
--backup_flags \
--skip_flagging \
--msin /project/lofarvwf/Share/jdejong/output/ELAIS/ALL_128h/6asec_sets/${LNUM}_6asec.ms \
$SB
