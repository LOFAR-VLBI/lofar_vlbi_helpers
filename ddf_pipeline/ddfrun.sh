#!/bin/bash
#SBATCH -N 1
#SBATCH -c 60
#SBATCH -t 240:00:00
##SBATCH --constraint=skylake
#SBATCH -p infinite

#pipeline.cfg from https://github.com/mhardcastle/ddf-pipeline/blob/master/examples/tier1-minimal.cfg

unset DDF_PIPELINE_DATABASE
export SINGULARITYENV_RCLONE_CONFIG_DIR=/project/lotss/Software/prefactor-operations/macaroons/
export SINGULARITYENV_SDR_TOKEN=c49c6bb3-d074-a44d-4fca-1d3f7458055d
export SINGULARITYENV_PREPEND_PATH=/project/lotss/Software/ddf-pipeline/scripts:$PATH
export SINGULARITYENV_PREPEND_PYTHONPATH=/project/lotss/Software/prefactor-operations/lotss-query/:$PYTHONPATH
export SINGULARITYENV_PREPEND_PYTHONPATH=/project/lotss/Software/ddf-pipeline/utils:$PYTHONPATH
export SINGULARITYENV_PREPEND_PYTHONPATH=/project/lotss/Software/lotss-hba-survey/:$PYTHONPATH
export SINGULARITYENV_DDF_PIPELINE_CATALOGS=/project/lotss/Software/ddf-operations/DDF-RUNS/bootstrap-cats/bootstrap-cats
./find-cpus.sh

singularity exec -B /scratch/,/home/lotss-tshimwell/,/project/lotss/ /project/lotss/Software/ddf-operations/DDF-RUNS/ddf_py3_d11.simg make_mslists.py
singularity exec -B /scratch/,/home/lotss-tshimwell/,/project/lotss/ /project/lotss/Software/ddf-operations/DDF-RUNS/ddf_py3_d11.simg pipeline.py pipeline.cfg
