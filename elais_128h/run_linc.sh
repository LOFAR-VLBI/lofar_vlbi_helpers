#!/bin/bash
#SBATCH -c 60
#SBATCH --output=linc_%j.out
#SBATCH --error=linc_%j.err
#SBATCH -t 50:00:00

FLOCSRUNNERS=/project/wfedfn/Software/flocs/runners

STARTDIR=$PWD

#SINGULARITY SETTINGS
SING_BIND=$( python3 $HOME/parse_settings.py --BIND )

SIMG=/project/wfedfn/Software/singularity/flocs_v5.5.1_znver2_znver2.sif

#GET ORIGINAL SCRIPT DIRECTORY
if [ -n "${SLURM_JOB_ID:-}" ] ; then
SCRIPT=$(scontrol show job "$SLURM_JOB_ID" | awk -F= '/Command=/{print $2}')
SCRIPT_DIR=$( echo ${SCRIPT%/*} )
else
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
fi

ulimit -S -n 30000

# echo "Run LINC calibrator from $SCRIPT_DIR on Data in $STARTDIR/calibrator"
# cd calibrator



# # Cleanup old run
# if ls L??????_LINC_calibrator 1> /dev/null 2>&1; then
#     rm -rf L??????_LINC_calibrator
#     rm job_output_full.txt
# fi

# # Ensure < 168 MHz
# singularity exec -B ${SING_BIND} ${SIMG} python ~/scripts/lofar_vlbi_helpers/elais_128h/download_scripts/removebands.py --freqcut 168 --datafolder data

# # Run LINC calibrator

# singularity exec -B ${SING_BIND} ${SIMG} $FLOCSRUNNERS/run_LINC_calibrator_HBA.sh -d $STARTDIR/calibrator/data -l /project/wfedfn/Software/LINC

# mv tmp.* linc_calibrator_output
# cd ../

echo "Run LINC target from $SCRIPT_DIR on Data in $STARTDIR/target"
cd target

# Cleanup old run
if ls L??????_LINC_target 1> /dev/null 2>&1; then
    rm -rf L??????_LINC_target
    rm job_output_full.txt
fi

# Ensure < 168 MHz
singularity exec -B ${SING_BIND} ${SIMG} python ~/scripts/lofar_vlbi_helpers/elais_128h/download_scripts/removebands.py --freqcut 168 --datafolder data

# Run LINC target

singularity exec -B ${SING_BIND} ${SIMG} $FLOCSRUNNERS/run_LINC_target_HBA.sh -l /project/wfedfn/Software/LINC -d $STARTDIR/target/data -f /project/wfedfn/Software/flocs/ -c $STARTDIR/calibrator/*_LINC_calibrator/results_LINC_calibrator/cal_solutions.h5 -e "--make_structure_plot=False --selfcal=True --calib_nchan=1 --num_SBs_per_group=-1" 


cd ../