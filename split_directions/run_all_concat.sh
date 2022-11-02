#!/bin/bash

#############  WRITTEN BY FRITS SWEIJEN   #############

for p in $(ls -d output_pybdsfcat/121MHz/ILTJ*.ms); do
	if [ ! -d /project/lofarvwf/Share/ELAIS-N1/long_baseline_dd/step2_find_calibrators/$(basename $p .ms)_concat.ms ]; then
		echo Dispatching concat for $(basename $p)
		cat launch_concat_cals.sh | sed -e "s?MYPOINTING?$(basename $p)?g" > tmpjob.sh
		sbatch tmpjob.sh
	fi
done