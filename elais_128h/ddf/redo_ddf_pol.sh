#!/bin/bash
#SBATCH -c 60
#SBATCH -p normal
#SBATCH --constraint=rome
#SBATCH --mail-type=FAIL,END
#SBATCH --mail-user=petley@strw.leidenuniv.nl
#SBATCH --output=ddf_%j.out
#SBATCH --error=ddf_%j.err
#SBATCH --time=4-00:00:00

#LINC TARGET FOLDER
START=$PWD
OUTPUT=$PWD/ddf_pol
RUNDIR=$TMPDIR/ddf_pol

mkdir -p $RUNDIR
mkdir -p $OUTPUT

SIMG=flocs_v5.5.1_znver2_znver2.sif

cd $RUNDIR

#wget https://lofar-webdav.grid.sara.nl/software/shub_mirror/tikk3r/lofar-grid-hpccloud/amd/${SIMG}
cp /home/wfedfn-jpetley/scripts/lofar_vlbi_helpers/elais_128h/ddf/pipeline_pol.cfg .
cp /project/wfedfn/Software/singularity/flocs_v5.5.1_znver2_znver2.sif .
#wget https://raw.githubusercontent.com/jwpetley/lofar_vlbi_helpers/refs/heads/main/elais_128h/ddf/pipeline_pol.cfg
#wget https://public.spider.surfsara.nl/project/lofarvwf/jdejong/singularities/flocs_v5.1.0_znver2_znver2_test.sif

cp -r $START/target/L??????_LINC_target/results_LINC_target/results/*.ms .

mv L720380_126MHz_uv_pre-cal.ms L720380_127MHz_uv_pre-cal.ms
mv L720380_128MHz_uv_pre-cal.ms L720380_129MHz_uv_pre-cal.ms

singularity exec -B $PWD,$OUTPUT $SIMG make_mslists.py
singularity exec -B $PWD,$OUTPUT $SIMG pipeline.py pipeline_pol.cfg


cp -r * $OUTPUT

cd $OUTPUT


