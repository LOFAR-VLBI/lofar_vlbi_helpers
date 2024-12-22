from glob import glob
import os
import pandas as pd
import casacore.tables as ct
import numpy as np
import re

def parse_l_number(path):
    # Use regular expression to find the L-number (L followed by 6 digits)
    match = re.search(r'L\d{6}', path)

    if match:
        return match.group(0)
    else:
        return None

polarization=False
lowres=True

LNUM=parse_l_number(os.getcwd())

def make_selfcal_script(solint, ms, preapply):
    """

    :param solint: solution interval in minutes
    :param ms: measurement set
    :return:
    """

    t = ct.table(ms, readonly=True, ack=False)
    time = np.unique(t.getcol('TIME'))
    t.close()

    deltime = np.abs(time[1]-time[0])

    # solint in minutes
    solint_scalarphase_1 = min(max(deltime/60, np.sqrt(solint)), 3)
    solint_scalarphase_2 = min(max(deltime/60, np.sqrt(1.5*solint)), 5)

    solint_complexgain_1 = max(16.0, 20*solint)

    cg_cycle_1 = 3

    if solint_complexgain_1/60 > 4:
        cg_cycle_1 = 999
    elif solint_complexgain_1/60 > 3:
        solint_complexgain_1 = 240.

    smoothness_phase = 10.0

    if solint<3:
        smoothness_complex = 5.0
    elif solint<8:
        smoothness_complex = 10.0
    else:
        smoothness_complex = 15.0


    print("solint scalarphase non-close-german: "+str(solint_scalarphase_1)+" minutes")
    print("solint scalarphase all international: "+str(solint_scalarphase_2)+" minutes")

    print("solint scalarcomplexgain non-close-german: "+str(solint_complexgain_1)+" minutes")

    if polarization:
        pol=" --makeimage-fullpol "
    else:
        pol=''

    if lowres:
        lr=" --makeimage-ILTlowres-HBA "
    else:
        lr=''

    H5=f'/project/lofarvwf/Share/jdejong/output/ELAIS/ALL_128h/6asec_sets/joinedsolutions/merged_selfcalcyle002_{LNUM}_6asec.ms.copy.avg.h5'

    script=f"""#!/bin/bash
#SBATCH -c 15
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=jurjendejong@strw.leidenuniv.nl
#SBATCH --constraint=amd

#SINGULARITY SETTINGS
SIMG=$( python3 $HOME/parse_settings.py --SIMG )
BIND=$( python3 $HOME/parse_settings.py --BIND )
echo "SINGULARITY IS $SIMG"
#SCRIPTS
lofar_facet_selfcal=$( python3 $HOME/parse_settings.py --facet_selfcal )
lofar_helpers=$( python3 $HOME/parse_settings.py --lofar_helpers )

singularity exec -B $BIND $SIMG python $lofar_helpers/ms_helpers/remove_flagged_stations.py --overwrite {ms}
singularity exec -B $BIND $SIMG python $lofar_helpers/h5_helpers/find_closest_h5.py --h5_in {H5} --msin {ms}
singularity exec -B $BIND $SIMG python $lofar_helpers/h5_merger.py -in output_h5s/source_0.h5 -out preapply.h5 --propagate_flags -ms {ms} --add_ms_stations
singularity exec -B $BIND $SIMG python $lofar_helpers/ms_helpers/applycal.py --msout {ms}.tmp --h5 preapply.h5 {ms}

rm -rf {ms}
mv {ms}.tmp {ms}

singularity exec -B $BIND $SIMG \\
python $lofar_facet_selfcal \\
-i selfcal \\
--phaseupstations='core' \\
--forwidefield \\
--autofrequencyaverage \\
--update-multiscale \\
--soltypecycles-list="[0,0,{cg_cycle_1}]" \\
--soltype-list="['scalarphase','scalarphase','scalarcomplexgain']" \\
--smoothnessconstraint-list="[{smoothness_phase},{smoothness_phase},{smoothness_complex}]" \\
--smoothnessreffrequency-list="[120.0,120.0,0.0]" \\
--smoothnessspectralexponent-list="[-1.0,-1.0,-1.0]" \\
--solint-list="['{int(solint_scalarphase_1*60)}s','{int(solint_scalarphase_2*60)}s','{int(solint_complexgain_1*60)}s']" \\
--uvmin=20000 \\
--imsize=2048 \\
--resetsols-list="['alldutchandclosegerman','alldutch','alldutch']" \\
--paralleldeconvolution=1024 \\
--targetcalILT='scalarphase' \\
--stop=12 \\
--flagtimesmeared \\
--compute-phasediffstat \\
--get-diagnostics \\
--helperscriptspath=/project/lofarvwf/Software/lofar_facet_selfcal \\
--helperscriptspathh5merge=/project/lofarvwf/Software/lofar_helpers {pol}{lr}\\
{ms}
"""

    f = open("selfcal_script.sh", "w")
    f.write(script)
    f.close()


if __name__ == "__main__":


    mss = glob('*.ms')

    phasediff_output = '/project/lofarvwf/Share/jdejong/output/ELAIS/final_dd_selection.csv'
    phasediff = pd.read_csv(phasediff_output)

    for ms in mss:

        print(ms)

        sourceid = ms.split("_")[0]

        solint = phasediff[phasediff['Source_id'].str.split('_').str[0] == sourceid].best_solint.min()
        make_selfcal_script(solint, ms, False)

        tasks = ['mkdir -p '+sourceid+'_selfcal',
                 'mv '+ms+' '+sourceid+'_selfcal',
                 'mv selfcal_script.sh '+sourceid+'_selfcal']
        os.system(' && '.join(tasks))
    print("---RUN---\nfor P in P?????; do cd $P && sbatch selfcal_script.sh && cd ../; done")
