#!/bin/bash
#SBATCH -c 45 --job-name=aoflagger --constraint=amd -t 10:00:00

SIMG=$( python3 $HOME/parse_settings.py --SIMG )
SING_BIND=$( python3 $HOME/parse_settings.py --BIND )

SB=$1

RUNDIR=$TMPDIR/subtract_${SLURM_ARRAY_TASK_ID}
OUTDIR=$PWD

mkdir -p $RUNDIR
cp -r $SB $RUNDIR
cp $SIMG $RUNDIR
cd $RUNDIR

singularity exec -B $PWD ${SIMG##*/} aoflagger ${SB##*/}

mv ${SB##*/} $OUTDIR/flagged_${SB##*/}
