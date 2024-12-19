#!/bin/bash
#SBATCH --output=delay_%j.out
#SBATCH --error=delay_%j.err

#NOTE: works only with TOIL>6.0.0

#### UPDATE THESE ####

export TOIL_SLURM_ARGS="--export=ALL --job-name delaycal -p normal -t 12:00:00"

SING_BIND="/project/lofarvwf/Software,/project/lofarvwf/Share,/project/lofarvwf/Public"
DELAYCAL=/project/lofarvwf/Share/jdejong/output/ELAIS/delaycalibrator.csv
CONFIG=/project/lofarvwf/Share/jdejong/output/ELAIS/delaysolve_config.txt


######################

# SETUP ENVIRONMENT

export DDFOLDER=$(realpath "../ddf")
export TARGETDATA=$(realpath "../target/data")
export SOLSET=$(realpath "$(ls ../target/L*_LINC_target/results_LINC_target/cal_solutions.h5)")

# set up software
#python3 -m venv /tmp/myvenv
#source /tmp/myvenv/bin/activate
pip install toil[cwl]

mkdir -p software
cd software
git clone https://git.astron.nl/RD/VLBI-cwl.git VLBI_cwl
git clone https://github.com/tikk3r/flocs.git
git clone https://github.com/jurjen93/lofar_helpers.git
git clone https://github.com/rvweeren/lofar_facet_selfcal.git
git clone https://git.astron.nl/RD/LINC.git
git clone https://github.com/revoltek/losoto
mkdir scripts
cp LINC/scripts/* scripts
cp VLBI_cwl/scripts/* scripts
SCRIPTS_PATH=$PWD/scripts
SING_BIND=${SING_BIND}",${SCRIPTS_PATH}:/opt/lofar/DynSpecMS"
PYPATH=${PWD}/VLBI_cwl/scripts:${PWD}/LINC/scripts:\$PYTHONPATH
PTH=${PWD}/VLBI_cwl/scripts:${PWD}/LINC/scripts:\$PATH
cd ../

# set up singularity
export SIMG=vlbi-cwl.sif
mkdir -p singularity
wget https://lofar-webdav.grid.sara.nl/software/shub_mirror/tikk3r/lofar-grid-hpccloud/amd/flocs_v5.0.0_znver2_znver2_aocl_cuda.sif -O singularity/$SIMG
mkdir -p singularity/pull
cp singularity/$SIMG singularity/pull/$SIMG

export LINC_DATA_ROOT=$PWD/software/LINC
export VLBI_DATA_ROOT=$PWD/software/VLBI_cwl

export APPTAINER_CACHEDIR=$PWD/singularity
export CWL_SINGULARITY_CACHE=$APPTAINER_CACHEDIR
export APPTAINERENV_LINC_DATA_ROOT=$LINC_DATA_ROOT
export APPTAINERENV_VLBI_DATA_ROOT=$VLBI_DATA_ROOT
export APPTAINERENV_PREPEND_PATH=$LINC_DATA_ROOT/scripts:$VLBI_DATA_ROOT/scripts
export APPTAINERENV_PYTHONPATH=$VLBI_DATA_ROOT/scripts:$LINC_DATA_ROOT/scripts:\$PYTHONPATH
export APPTAINER_BIND=$SING_BIND
export TOIL_CHECK_ENV=True

########################

# PREP SOLUTIONS

# convert DDF solution files to h5parm
C=0
for KILLMSFILE in $DDFOLDER/SOLSDIR/*MHz_uv_pre-cal.ms/*DIS2*.sols.npz; do
  echo ${KILLMSFILE}
  singularity exec singularity/$SIMG \
  python software/losoto/bin/killMS2H5parm.py \
  --solset sol000 \
  --verbose \
  DDF${C}.h5 \
  ${KILLMSFILE}

  ((C++))  # increment the counter
done

# merge h5parm into 1 file
singularity exec singularity/$SIMG \
python software/lofar_helpers/h5_merger.py \
--h5_tables DDF*.h5 \
--h5_out DDF_merged.h5 \
--propagate_flags \
--add_ms_stations \
--ms $( ls $TARGETDATA/*.MS -1d | head -n 1) \
--merge_diff_freq \
--h5_time_freq true

########################

# MAKE CONFIG FILE

singularity exec singularity/$SIMG \
python software/flocs/runners/create_ms_list.py \
VLBI \
delay-calibration \
--solset=$SOLSET \
--configfile=$CONFIG \
--h5merger=$PWD/software/lofar_helpers \
--selfcal=$PWD/software/lofar_facet_selfcal \
--delay_calibrator=$DELAYCAL \
--linc=$PWD/software/LINC \
$TARGETDATA
#--ddf_solset=$PWD/DDF_merged.h5 \
#--ddf_solsdir=$DDFOLDER/SOLSDIR \


# update json
jq '. + {"ms_suffix": ".MS"}' mslist_VLBI_delay_calibration.json > temp.json && mv temp.json mslist_VLBI_delay_calibration.json
jq '. + {"reference_stationSB": 77}' mslist_VLBI_delay_calibration.json > temp.json && mv temp.json mslist_VLBI_delay_calibration.json

#source ${VENV}/bin/activate

TGSSphase_final_lines=$(singularity exec -B /project/lofarvwf singularity/$SIMG python software/lofar_helpers/h5_merger.py -in=$SOLSET | grep "TGSSphase" | wc -l)
# Check if the line count is greater than 1
if [ "$TGSSphase_final_lines" -ge 1 ]; then
    echo "Use TGSSphase_final"
    jq '. + {"phasesol": "TGSSphase_final"}' mslist_VLBI_delay_calibration.json > temp.json && mv temp.json mslist_VLBI_delay_calibration.json
else
    echo "Use TGSSphase"
    jq '. + {"phasesol": "TGSSphase"}' mslist_VLBI_delay_calibration.json > temp.json && mv temp.json mslist_VLBI_delay_calibration.json
fi

########################

# MAKE TOIL STRUCTURE

# make folder for running toil
WORKDIR=$PWD/workdir
OUTPUT=$PWD/outdir
JOBSTORE=$PWD/jobstore
LOGDIR=$PWD/logs
TMPD=$PWD/tmpdir

mkdir -p $WORKDIR
mkdir -p $OUTPUT
mkdir -p $LOGDIR

########################

# RUN TOIL

toil-cwl-runner \
--retryCount 0 \
--singularity \
--disableCaching \
--logFile full_log.log \
--writeLogs ${LOGDIR} \
--outdir ${OUTPUT} \
--tmp-outdir-prefix ${TMPD}/ \
--jobStore ${JOBSTORE} \
--workDir ${WORKDIR} \
--coordinationDir ${OUTPUT} \
--disableAutoDeployment True \
--batchSystem slurm \
--noStdOutErr \
--maxJobs 25 \
--logCritical \
--jobStoreTimeout 120 \
--setEnv PATH=$VLBI_DATA_ROOT/scripts:$LINC_DATA_ROOT/scripts:\$PATH \
--setEnv PYTHONPATH=$VLBI_DATA_ROOT/scripts:$LINC_DATA_ROOT/scripts:\$PYTHONPATH \
/project/lofarvwf/Software/VLBI-cwl/workflows/delay-calibration.cwl mslist_VLBI_delay_calibration.json

#toil-cwl-runner \
#--retryCount 2 \
#--singularity \
#--disableCaching \
#--writeLogsFromAllJobs True \
#--logFile full_log.log \
#--writeLogs ${LOGDIR} \
#--outdir ${OUTPUT} \
#--tmp-outdir-prefix ${TMPD}/ \
#--jobStore ${JOBSTORE} \
#--workDir ${WORKDIR} \
#--coordinationDir ${OUTPUT} \
#--disableAutoDeployment True \
#--bypass-file-store \
#--batchSystem slurm \
#--setEnv PATH=$VLBI_DATA_ROOT/scripts:$LINC_DATA_ROOT/scripts:\$PATH \
#--setEnv PYTHONPATH=$VLBI_DATA_ROOT/scripts:$LINC_DATA_ROOT/scripts:\$PYTHONPATH \
#/project/lofarvwf/Software/VLBI-cwl/workflows/delay-calibration.cwl mslist_VLBI_delay_calibration.json
#--cleanWorkDir never \ --> for testing

########################

#deactivate
