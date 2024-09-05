#!/bin/bash
#SBATCH -c 15

SIMG=/project/lofarvwf/Software/singularity/lofar_sksp_v4.4.0_znver2_znver2_aocl4.sif

FACET=$1
RUNDIR=$TMPDIR/selfcal_$1
SCRIPT=$( python3 $HOME/parse_settings.py --facet_selfcal )
OUTDIR=$PWD/facet_$1/1.2imaging

cd $OUTDIR

singularity exec -B /project/lofarvwf/Share/jdejong/,$PWD,/project/lofarvwf/Software/lofar_helpers/ $SIMG python \
/project/lofarvwf/Software/lofar_helpers/ms_helpers/concat_with_dummies.py \
--ms avg*L68*.ms --concat_name concat_L68.ms --time_avg 3 --freq_avg 4

singularity exec -B /project/lofarvwf/Share/jdejong/,$PWD,/project/lofarvwf/Software/lofar_helpers/ $SIMG python \
/project/lofarvwf/Software/lofar_helpers/ms_helpers/concat_with_dummies.py \
--ms avg*L76*.ms --concat_name concat_L76.ms --time_avg 3 --freq_avg 4

singularity exec -B /project/lofarvwf/Share/jdejong/,$PWD,/project/lofarvwf/Software/lofar_helpers/ $SIMG python \
/project/lofarvwf/Software/lofar_helpers/ms_helpers/concat_with_dummies.py \
--ms avg*L81*.ms --concat_name concat_L81.ms --time_avg 3 --freq_avg 4

singularity exec -B /project/lofarvwf/Share/jdejong/,$PWD,/project/lofarvwf/Software/lofar_helpers/ $SIMG python \
/project/lofarvwf/Software/lofar_helpers/ms_helpers/concat_with_dummies.py \
--ms avg*L79*.ms --concat_name concat_L79.ms --time_avg 3 --freq_avg 4

mkdir -p $RUNDIR

cp -r concat_L??.ms $RUNDIR
cp $SIMG $RUNDIR
cp $SCRIPT $RUNDIR
cd $RUNDIR

singularity exec -B $PWD,$OUTDIR,/project/lofarvwf/Software lofar_sksp_v4.4.0_znver2_znver2_aocl4.sif \
python facetselfcal.py \
--parallelgridding=3 \
--multiscale \
--start=0 \
--stop=10 \
--imsize=4000 \
--uvmin=750 \
--soltype-list="['scalarphase','scalarphase','scalarcomplexgain']" \
--soltypecycles-list="[0,0,2]" \
--solint-list="['1min','5min','30m']" \
--nchan-list="[1,1,1]" \
--smoothnessconstraint-list="[10.,20.,15]" \
--smoothnessreffrequency-list="[120.0,120.0,0.0]" \
--antennaconstraint-list="[None,None,None]" \
--resetsols-list="['core',None,None]" \
--forwidefield \
--removeinternational \
--skipbackup \
--paralleldeconvolution=1600 \
--noarchive \
-i selfcal_$1 \
--useaoflagger \
--helperscriptspath=/project/lofarvwf/Software/lofar_facet_selfcal \
--helperscriptspathh5merge=/project/lofarvwf/Software/lofar_helpers \
concat_L??.ms

mkdir $OUTDIR/selfcaloutput
cp *-MFS*.fits $OUTDIR/selfcaloutput
cp *.png $OUTDIR/selfcaloutput
cp merged*.h5 $OUTDIR/selfcaloutput
cp -r plotlosoto* $OUTDIR/selfcaloutput
