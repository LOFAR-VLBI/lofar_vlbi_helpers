#!/bin/bash
#SBATCH -N 1 -c 32 --job-name=test_image --exclusive --constraint=napl

#re="L[0-9][0-9][0-9][0-9][0-9][0-9]"
#re_subband="([^.]+)"
#if [[ $PWD =~ $re ]]; then OBSERVATION=${BASH_REMATCH}; fi

DDF_OUTPUT=/project/lotss/Public/jdejong/ELAIS/${OBSERVATION}/ddf/

export SIMG=/project/lofarvwf/Software/singularity/lofar_sksp_v3.4_x86-64_generic_noavx512_ddf.sif

MSIN=$1
#
#mkdir imagetest_${MSIN}
#
#cp -r ${MSIN} imagetest_${MSIN}
#cp ${DDF_OUTPUT}/DDS3_full_*_smoothed.npz imagetest_${MSIN}
#cp ${DDF_OUTPUT}/DDS3_full_*_merged.npz imagetest_${MSIN}
#cp ${DDF_OUTPUT}/image_full_ampphase_di_m.NS.mask01.fits imagetest_${MSIN}
#cp ${DDF_OUTPUT}/SOLSDIR imagetest_${MSIN}
#cp ${DDF_OUTPUT}/image_dirin_SSD_m.npy.ClusterCat.npy imagetest_${MSIN}
#cp ${DDF_OUTPUT}/image_full_ampphase_di_m.NS.DicoModel imagetest_${MSIN}
#
#cd imagetest_${MSIN}
#
singularity exec -B $PWD,/project,/home/lofarvwf-jdejong/scripts $SIMG \
DPPP \
msin=${MSIN} \
msout=${MSIN}-cal.ms \
msin.datacolumn=DATA \
steps=[filter,averager] \
numthreads=24 \
filter.baseline='[CR]S*&&*' \
filter.remove=true \
averager.timestep=8 \
averager.freqstep=8 \
msout.storagemanager=dysco \
msin.weightcolumn=WEIGHT_SPECTRUM \
msout.writefullresflag=False

echo ${MSIN}-cal.ms > mslist.txt

singularity exec -B $PWD,/project,/home/lofarvwf-jdejong/scripts $SIMG DDF.py \
--Output-Name=test_sub --Data-MS=mslist.txt --Deconv-PeakFactor \
0.001000 --Data-ColName DATA --Parallel-NCPU=32 --Beam-CenterNorm=1 \
--Deconv-CycleFactor=0 --Deconv-MaxMinorIter=1000000 \
--Deconv-MaxMajorIter=1 --Deconv-Mode SSD --Beam-Model=LOFAR \
--Beam-LOFARBeamMode=A --Weight-Robust -0.500000 --Image-NPix=21500 \
--CF-wmax 50000 --CF-Nw 100 --Output-Also onNeds --Image-Cell 1.500000 \
--Facets-NFacets=11 --SSDClean-NEnlargeData 0 --Freq-NDegridBand 1 \
--Beam-NBand 1 --Facets-DiamMax 1.5 --Facets-DiamMin 0.1 \
--Deconv-RMSFactor=3.000000 --SSDClean-ConvFFTSwitch 10000 --Data-Sort 1 \
--Cache-Dir=. --Log-Memory 1 --GAClean-RMSFactorInitHMP 1.000000 \
--GAClean-MaxMinorIterInitHMP 10000.000000 \
--GAClean-AllowNegativeInitHMP True --DDESolutions-SolsDir=SOLSDIR \
--Cache-Weight=reset --Output-Mode=Dirty --Predict-ColName DD_PREDICT \
--Output-RestoringBeam 6.000000 --Freq-NBand=2 --RIME-DecorrMode=FT \
--SSDClean-SSDSolvePars [S,Alpha] --SSDClean-BICFactor 0 --Mask-Auto=1 \
--Mask-SigTh=5.00 \
--Mask-External=image_full_ampphase_di_m.NS.mask01.fits \
--DDESolutions-GlobalNorm=None --DDESolutions-DDModeGrid=AP \
--DDESolutions-DDModeDeGrid=AP \
--DDESolutions-DDSols=[DDS3_full_smoothed,DDS3_full_slow_merged] \
--Selection-UVRangeKm=[0.100000,1000.000000] --GAClean-MinSizeInit=10 \
--Beam-Smooth=1 --Misc-IgnoreDeprecationMarking 1 \
