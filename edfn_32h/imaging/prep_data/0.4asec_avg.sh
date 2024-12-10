#!/bin/bash
#SBATCH -c 6
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=jurjendejong@strw.leidenuniv.nl
#SBATCH --job-name=prep_0.4
#SBATCH --array=0-100

#SINGULARITY SETTINGS
SING_BIND=$( python3 $HOME/parse_settings.py --BIND )
SIMG=$( python3 $HOME/parse_settings.py --SIMG )

echo $SLURM_JOB_NAME
echo $SIMG

pattern="/project/lofarvwf/Share/jdejong/output/ELAIS/ALL_L/apply_delaycal/applycal*.ms"
files=( $pattern )
MSIN=${files[${SLURM_ARRAY_TASK_ID}]}
read MSOUT <<< "${MSIN##*/}"

echo "Average data in DPPP..."

#Averaging to 2seconds and 8ch/SB
singularity exec -B ${SING_BIND} ${SIMG} DP3 \
msin=${MSIN} \
msout=avg0.4_${MSOUT} \
msin.datacolumn=DATA \
msout.storagemanager=dysco \
msout.writefullresflag=False \
steps=[ps] \
ps.type=phaseshifter \
ps.phasecenter=[16h11m00.00000,54d57m00.0000]

echo "... Finished averaging data in DPPP"
