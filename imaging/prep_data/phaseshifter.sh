#!/bin/bash
#SBATCH -c 6
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=jurjendejong@strw.leidenuniv.nl
#SBATCH --job-name=prep_0.6
#SBATCH --array=0-100

#SINGULARITY SETTINGS
SING_BIND=$( python3 $HOME/parse_settings.py --BIND )
SIMG=$( python3 $HOME/parse_settings.py --SIMG )

echo $SLURM_JOB_NAME
echo $SIMG

pattern="*.ms"
files=( $pattern )
MSIN=${files[${SLURM_ARRAY_TASK_ID}]}
read MSOUT <<< "${MSIN##*/}"

echo "Phaseshifting..."

singularity exec -B ${SING_BIND} ${SIMG} DP3 \
msin=${MSIN} \
msin.orderms=False \
msin.missingdata=True \
msin.datacolumn=DATA \
msout.overwrite=True \
msout.storagemanager=dysco \
msout.writefullresflag=False \
steps=[ps] \
ps.type=phaseshifter \
ps.phasecenter=[16h11m00.00000,54d57m00.0000]

echo "... end Phaseshifting"
