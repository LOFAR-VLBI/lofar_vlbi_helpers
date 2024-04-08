#!/bin/bash
#SBATCH -t 1:00:00 -c 5

SIMG=vlbi-cwl.sif

TARGETDATA=$(realpath "../target/data")

# merge h5parm into 1 file
singularity exec -B /project/lofarvwf,$PWD singularity/$SIMG \
python software/lofar_helpers/h5_merger.py \
--h5_tables DDF*.h5 \
--h5_out DDF_merged.h5 \
--propagate_flags \
--add_ms_stations \
--ms $( ls $TARGETDATA/*.MS -1d | head -n 1) \
--merge_diff_freq \
--h5_time_freq true
