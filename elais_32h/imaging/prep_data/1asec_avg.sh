#!/bin/bash
#SBATCH -c 6
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=jurjendejong@strw.leidenuniv.nl
#SBATCH --job-name=prep_1asec_1sec
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

#Average to 4seconds and 4ch/SB
singularity exec -B ${SING_BIND} ${SIMG} DP3 \
msin=${MSIN} \
msout=avg1.2_${MSOUT} \
msin.datacolumn=DATA \
msout.storagemanager=dysco \
msout.writefullresflag=False \
steps=[avg,ps] \
avg.type=averager \
avg.freqstep=4 \
avg.timeresolution=4 \
ps.type=phaseshifter \
ps.phasecenter=[16h11m00.00000,54d57m00.0000]

echo "... Finished averaging data in DPPP"
