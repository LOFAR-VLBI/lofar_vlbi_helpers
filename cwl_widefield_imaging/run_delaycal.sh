#!/bin/bash
#SBATCH --output=delay_%j.out
#SBATCH --error=delay_%j.err

######################
#### UPDATE THESE ####
######################

export TOIL_SLURM_ARGS="--export=ALL --job-name delaycal -p normal"

SING_BIND="/project,/project/lofarvwf/Software,/project/lofarvwf/Share,/project/lofarvwf/Public,/home/lofarvwf-jdejong"
DELAYCAL=/project/lofarvwf/Share/jdejong/output/ELAIS/delaycalibrator.csv
CONFIG=/project/lofarvwf/Share/jdejong/output/ELAIS/delaysolve_config.txt

VENV=/home/lofarvwf-jdejong/venv

DDFOLDER=$(realpath "../ddf")
TARGETDATA=$(realpath "../target/data")
SOLSET=$(realpath "$(ls ../target/L*_LINC_target/results_LINC_target/cal_solutions.h5)")

#####################
######################

# set up software
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
SIMG=vlbi-cwl.sif
mkdir -p singularity
wget https://public.spider.surfsara.nl/project/lofarvwf/fsweijen/flocs_v5.1.0_znver2_znver2_test.sif -O singularity/$SIMG
mkdir -p singularity/pull
cp singularity/$SIMG singularity/pull/$SIMG

CONTAINERSTR=$(singularity --version)
if [[ "$CONTAINERSTR" == *"apptainer"* ]]; then
  export APPTAINER_CACHEDIR=$PWD/singularity
  export APPTAINER_TMPDIR=$APPTAINER_CACHEDIR/tmp
  export APPTAINER_PULLDIR=$APPTAINER_CACHEDIR/pull
  export APPTAINER_BIND=$SING_BIND
  export APPTAINERENV_PYTHONPATH=$PYPATH
  export APPTAINERENV_PATH=$PTH
else
  export SINGULARITY_CACHEDIR=$PWD/singularity
  export SINGULARITY_TMPDIR=$SINGULARITY_CACHEDIR/tmp
  export SINGULARITY_PULLDIR=$SINGULARITY_CACHEDIR/pull
  export SINGULARITY_BIND=$SING_BIND
  export SINGULARITYENV_PYTHONPATH=$PYPATH
  export SINGULARITYENV_PYTHONPATH=$PTH
fi

export SING_USER_DEFINED_PATH=$PTH
export CWL_SINGULARITY_CACHE=$APPTAINER_CACHEDIR
export TOIL_CHECK_ENV=True
export LINC_DATA_ROOT=$PWD/software/LINC

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
--solset=$(realpath "$(ls ../target/L*_LINC_target/results_LINC_target/cal_solutions.h5)") \
--configfile=$CONFIG \
--h5merger=$PWD/software/lofar_helpers \
--selfcal=$PWD/software/lofar_facet_selfcal \
--delay_calibrator=$DELAYCAL \
--linc=$PWD/software/LINC \
--ddf_solsdir=$DDFOLDER/SOLSDIR \
$TARGETDATA

# update json
jq --arg nv "$PWD/DDF_merged.h5" '. + {"ddf_solset": {"class": "File", "path": $nv}}' mslist_VLBI_delay_calibration.json > temp.json && mv temp.json mslist_VLBI_delay_calibration.json
jq --arg nv "$DDFOLDER" '. + {"ddf_rundir": {"class": "Directory", "path": $nv}}' mslist_VLBI_delay_calibration.json > temp.json && mv temp.json mslist_VLBI_delay_calibration.json
jq --arg nv "$DDFOLDER/SOLSDIR" '. + {"ddf_solsdir": {"class": "Directory", "path": $nv}}' mslist_VLBI_delay_calibration.json > temp.json && mv temp.json mslist_VLBI_delay_calibration.json
jq '. + {"subtract_lotss_model": true}' mslist_VLBI_delay_calibration.json > temp.json && mv temp.json mslist_VLBI_delay_calibration.json
jq '. + {"ms_suffix": ".MS"}' mslist_VLBI_delay_calibration.json > temp.json && mv temp.json mslist_VLBI_delay_calibration.json

source ${VENV}/bin/activate

TGSSphase_final_lines=$(singularity exec singularity/$SIMG python software/lofar_helpers/h5_merger.py -in=$SOLSET | grep "TGSSphase_final" | wc -l)
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

mkdir -p ${TMPD}_interm
mkdir -p $WORKDIR
mkdir -p $OUTPUT
mkdir -p $LOGDIR


########################

# RUN TOIL

toil-cwl-runner \
--no-read-only \
--retryCount 0 \
--singularity \
--disableCaching \
--writeLogsFromAllJobs True \
--logFile full_log.log \
--writeLogs ${LOGDIR} \
--outdir ${OUTPUT} \
--tmp-outdir-prefix ${TMPD}/ \
--jobStore ${JOBSTORE} \
--workDir ${WORKDIR} \
--coordinationDir ${OUTPUT} \
--tmpdir-prefix ${TMPD}_interm/ \
--disableAutoDeployment True \
--bypass-file-store \
--preserve-entire-environment \
--batchSystem slurm \
--cleanWorkDir onSuccess \
software/VLBI_cwl/workflows/delay-calibration.cwl mslist_VLBI_delay_calibration.json

########################

deactivate
