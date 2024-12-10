#!/bin/bash
#SBATCH -N 1 -c 31 --job-name=test_image --exclusive

re="L[0-9][0-9][0-9][0-9][0-9][0-9]"
re_subband="([^.]+)"
if [[ $PWD =~ $re ]]; then OBSERVATION=${BASH_REMATCH}; fi

DDF_OUTPUT=/project/lotss/Public/jdejong/ELAIS/${OBSERVATION}/ddf

SIMG=$( python $HOME/parse_settings.py --SIMG )
SING_BIND=$( python $HOME/parse_settings.py --BIND )
echo "SINGULARITY IS $SIMG"

singularity exec -B $SING_BIND $SIMG CleanSHM.py

#
MSIN=$1

mkdir imagetest_${MSIN}

cp -r ${MSIN} imagetest_${MSIN}
cp ${DDF_OUTPUT}/DDS3_full_*_smoothed.npz imagetest_${MSIN}
cp ${DDF_OUTPUT}/DDS3_full_*_merged.npz imagetest_${MSIN}
cp ${DDF_OUTPUT}/image_full_ampphase_di_m.NS.mask01.fits imagetest_${MSIN}
cp ${DDF_OUTPUT}/SOLSDIR imagetest_${MSIN}
cp ${DDF_OUTPUT}/image_dirin_SSD_m.npy.ClusterCat.npy imagetest_${MSIN}
cp ${DDF_OUTPUT}/image_full_ampphase_di_m.NS.DicoModel imagetest_${MSIN}

cd imagetest_${MSIN}

singularity exec -B $SING_BIND $SIMG DPPP msin=${MSIN} test.parset


echo ${MSIN}-cal.ms > mslist.txt


singularity exec -B $SING_BIND $SIMG DDF.py \
--Output-Name=test_sub --Data-MS=mslist.txt --Deconv-PeakFactor \
0.001000 --Data-ColName DATA --Parallel-NCPU=32 --Beam-CenterNorm=1 \
--Deconv-CycleFactor=0 --Deconv-MaxMinorIter=1000000 \
--Deconv-MaxMajorIter=1 --Deconv-Mode SSD --Beam-Model=LOFAR \
--Beam-LOFARBeamMode=A --Weight-Robust -0.500000 --Image-NPix=20000 \
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
--Beam-Smooth=1 --Cache-ResetWisdom=True
