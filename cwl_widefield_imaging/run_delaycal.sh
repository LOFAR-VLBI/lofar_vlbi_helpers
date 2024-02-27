#!/bin/bash
#SBATCH --output=delay_%j.out
#SBATCH --error=delay_%j.err

#NOTE: works only with TOIL>6.0.0

#### UPDATE THESE ####

export TOIL_SLURM_ARGS="--export=ALL --job-name delaycal -p normal"

SING_BIND="/project,/project/lofarvwf/Software,/project/lofarvwf/Share,/project/lofarvwf/Public,/home/lofarvwf-jdejong"

DELAYCAL=/project/lofarvwf/Share/jdejong/output/ELAIS/delaycalibrator.csv

VENV=/home/lofarvwf-jdejong/venv

######################

#SETUP

DDFOLDER=$(realpath "../ddf")
TARGETFOLDER=$(realpath "../target")

# set up software
mkdir -p software
cd software
git clone -b widefield https://git.astron.nl/RD/VLBI-cwl.git VLBI_cwl
git clone https://github.com/tikk3r/flocs.git
git clone https://github.com/jurjen93/lofar_helpers.git
git clone https://github.com/rvweeren/lofar_facet_selfcal.git
git clone https://git.astron.nl/RD/LINC.git
git clone https://github.com/revoltek/losoto
cd ../

# set up singularity
SIMG=vlbi-cwl.sif
mkdir -p singularity
wget https://lofar-webdav.grid.sara.nl/software/shub_mirror/tikk3r/lofar-grid-hpccloud/amd/flocs_v4.5.0_znver2_znver2_aocl4_cuda.sif -O singularity/$SIMG
mkdir -p singularity/pull
cp singularity/$SIMG singularity/pull/$SIMG

CONTAINERSTR=$(singularity --version)
if [[ "$CONTAINERSTR" == *"apptainer"* ]]; then
  export APPTAINER_CACHEDIR=$PWD/singularity
  export APPTAINER_TMPDIR=$APPTAINER_CACHEDIR/tmp
  export APPTAINER_PULLDIR=$APPTAINER_CACHEDIR/pull
  export APPTAINER_BIND=$SING_BIND
  export APPTAINERENV_PYTHONPATH=${PWD}/software/VLBI_cwl/scripts:${PWD}/software/LINC/scripts:$PYTHONPATH
else
  export SINGULARITY_CACHEDIR=$PWD/singularity
  export SINGULARITY_TMPDIR=$SINGULARITY_CACHEDIR/tmp
  export SINGULARITY_PULLDIR=$SINGULARITY_CACHEDIR/pull
  export SINGULARITY_BIND=$SING_BIND
  export SINGULARITYENV_PYTHONPATH=${PWD}/software/VLBI_cwl/scripts:${PWD}/software/LINC/scripts:$PYTHONPATH
fi

export CWL_SINGULARITY_CACHE=$APPTAINER_CACHEDIR
export TOIL_CHECK_ENV=True
export LINC_DATA_ROOT=$PWD/software/LINC

########################

# PREP SOLUTIONS

# convert DDF solution files to h5parm
C=0
for KILLMSFILE in $DDFOLDER/DDS3_*.npz; do
  echo ${KILLMSFILE}
  singularity exec singularity/$SIMG \
  python software/losoto/bin/killMS2H5parm.py \
  --solset sol000 \
  --verbose \
  DDF${C}.h5 \
  ${KILLMSFILE}

  ((C++))  # Increment the counter
done

# merge h5parm into 1 file
singularity exec singularity/$SIMG \
python software/lofar_helpers/h5_merger.py \
--h5_tables DDF*.h5 \
--h5_out DDF_merged.h5 \
--propagate_flags

########################

#MAKE CONFIG FILE

singularity exec singularity/$SIMG \
python software/flocs/runners/create_ms_list.py \
VLBI \
delay-calibration \
--solset=$( ls /project/lofarvwf/Share/jdejong/output/ELAIS/L686906/L686906/target/L*_LINC_target/results_LINC_target/cal_solutions.h5 ) \
--configfile=$PWD/software/VLBI_cwl/facetselfcal_config.txt \
--h5merger=$PWD/software/lofar_helpers \
--selfcal=$PWD/software/lofar_facet_selfcal \
--delay_calibrator=$DELAYCAL \
--linc=$PWD/software/LINC \
--ddf_solset=$PWD/DDF_merged.h5 \
--ddf_solsdir=$DDFOLDER/SOLSDIR \
$TARGETFOLDER/data

########################

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

source ${VENV}/bin/activate

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
software/VLBI_cwl/workflows/delay-calibration.cwl mslist_VLBI_delay_calibration.json
#--cleanWorkDir never \ --> for testing

########################

deactivate
