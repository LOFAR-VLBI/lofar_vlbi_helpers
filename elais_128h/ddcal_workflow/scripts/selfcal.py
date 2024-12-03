from glob import glob
import os
import inspect
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
lowres=False

LNUM=parse_l_number(os.getcwd())

def make_selfcal_script(ms):
    """

    :param solint: solution interval in minutes
    :param ms: measurement set
    :return:
    """

    H5=f'/project/lofarvwf/Share/jdejong/output/ELAIS/{LNUM}/{LNUM}/ddcal_6asec/merged_skyselfcalcyle000_{LNUM}_6asec.ms.copy.avg.h5'

    script=f"""#!/bin/bash
#SBATCH -c 12
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
python $lofar_facet_selfcal --configpath {ms}.config.txt {ms}
"""

    f = open("selfcal_script.sh", "w")
    f.write(script)
    f.close()

def get_solint(ms, phasediff_output):
    """
    Get solution interval
    Args:
        ms: MeasurementSet
        phasediff_output: phasediff CSV output

    Returns: solution interval in minutes

    """

    phasediff = pd.read_csv(phasediff_output)
    sourceid = ms.split("/")[-1].split("_")[0]

    try:
        solint = phasediff[phasediff['Source_id'].str.split('_').str[0] == sourceid].best_solint.min()
    except: # depends on version
        solint = phasediff[phasediff['source'].str.split('_').str[0] == sourceid].best_solint.min()

    return solint

def make_config(solint, ms):
    """
    Make config for facetselfcal

    Args:
        solint: solution interval
        ms: MeasurementSet

    """

    with ct.table(ms, readonly=True, ack=False) as t:
        time = np.unique(t.getcol('TIME'))

    deltime = np.abs(time[1]-time[0])

    # solint in minutes
    solint_scalarphase_1 = min(max(deltime/60, np.sqrt(1.5*solint)), 3)
    solint_scalarphase_2 = min(max(deltime/60, np.sqrt(3*solint)), 5)
    solint_scalarphase_3 = min(max(1, 2*np.sqrt(solint)), 10)

    solint_complexgain_1 = max(20.0, 25*solint)
    solint_complexgain_2 = 2 * solint_complexgain_1

    # start ampsolve
    cg_cycle = 3

    if solint_complexgain_1/60 > 4:
        cg_cycle = 999
    elif solint_complexgain_1/60 > 3:
        solint_complexgain_1 = 240.

    if solint_complexgain_2/60 > 4:
        cg_cycle = 999
    elif solint_complexgain_2/60 > 3:
        solint_complexgain_2 = 240.


    soltypecycles_list = f'[0,0,{cg_cycle},1,{cg_cycle+1}]'
    soltype_list = "['scalarphase','scalarphase','scalaramplitude','scalarphase','scalarcomplexgain']"
    smoothnessreffrequency_list = "[120.0,120.0,0.0,120.0,0.0]"
    smoothnessspectralexponent_list = "[-1.0,-1.0,-1.0,-1.0,-1.0]"
    solint_list = f"['{int(solint_scalarphase_1*60)}s','{int(solint_scalarphase_2*60)}s','{int(solint_complexgain_1*60)}s','{int(solint_scalarphase_3*60)}s','{int(solint_complexgain_2*60)}s']"

    # adjusted settings based on solint/phasediff score
    if solint<0.3:
        uvmin=40000
        if not 'ILTJ161212.29+552303.8' in ms:
            resetsols_list = "['alldutchandclosegerman','alldutch','alldutch','core','core']"
        else:
            resetsols_list = "['alldutchandclosegerman','alldutch','alldutch','alldutch','alldutch']"
        smoothness_phase = 5.0
        smoothness_complex = 10.0
        smoothnessconstraint_list = f"[{smoothness_phase},{smoothness_phase},{smoothness_complex},{smoothness_phase * 2},{smoothness_complex+5.0}]"


    elif solint<1:
        uvmin=30000
        resetsols_list = "['alldutchandclosegerman','alldutch','alldutch','coreandfirstremotes','coreandfirstremotes']"
        smoothness_phase = 8.0
        smoothness_complex = 12.5
        smoothnessconstraint_list = f"[{smoothness_phase},{smoothness_phase},{smoothness_complex},{smoothness_phase * 1.5},{smoothness_complex+5.0}]"


    elif solint<3:
        uvmin=25000
        resetsols_list = "['alldutchandclosegerman','alldutch','alldutch','coreandallbutmostdistantremotes','coreandallbutmostdistantremotes']"
        smoothness_phase = 10.0
        smoothness_complex = 15.0
        smoothnessconstraint_list = f"[{smoothness_phase},{smoothness_phase},{smoothness_complex},{smoothness_phase * 1.5},{smoothness_complex+5.0}]"


    else:
        uvmin=20000
        soltypecycles_list = f'[0,0,{cg_cycle}]'
        soltype_list = "['scalarphase','scalarphase','scalarcomplexgain']"
        smoothness_phase = 10.0
        smoothness_complex = 20.0
        smoothnessconstraint_list = f"[{smoothness_phase},{smoothness_phase},{smoothness_complex}]"
        smoothnessreffrequency_list = "[120.0,120.0,0.0]"
        smoothnessspectralexponent_list = "[-1.0,-1.0,-1.0]"
        solint_list = f"['{int(solint_scalarphase_1*60)}s','{int(solint_scalarphase_2*60)}s','{int(solint_complexgain_1*60)}s']"
        resetsols_list = "['alldutchandclosegerman','alldutch','alldutch']"


    config=f"""imagename                       = "{parse_source_id(ms)}"
phaseupstations                 = "core"
forwidefield                    = True
autofrequencyaverage            = True
update_multiscale               = True
soltypecycles_list              = {soltypecycles_list}
soltype_list                    = {soltype_list}
smoothnessconstraint_list       = {smoothnessconstraint_list}
smoothnessreffrequency_list     = {smoothnessreffrequency_list}
smoothnessspectralexponent_list = {smoothnessspectralexponent_list}
solint_list                     = {solint_list}
uvmin                           = {uvmin}
imsize                          = 2048
resetsols_list                  = {resetsols_list}
paralleldeconvolution           = 1024
targetcalILT                    = "scalarphase"
stop                            = 10
flagtimesmeared                 = True
compute_phasediffstat           = True
get_diagnostics                 = True
parallelgridding                = 6
channelsout                     = 12
fitspectralpol                  = 5
"""

    # write to file
    with open(ms+".config.txt", "w") as f:
        f.write(config)

def parse_source_id(inp_str: str = None):
    """
    Parse ILTJ... source_id string

    Args:
        inp_str: ILTJ source_id

    Returns: parsed output

    """

    parsed_inp = re.findall(r'ILTJ\d+\..\d+\+\d+.\d+', inp_str)[0]

    return parsed_inp

if __name__ == "__main__":


    mss = glob('*.ms')

    phasediff_output = '/project/lofarvwf/Share/jdejong/output/ELAIS/final_dd_selection.csv'
    phasediff = pd.read_csv(phasediff_output)

    for ms in mss:

        print(ms)

        sourceid = ms.split("_")[0]

        solint = get_solint(ms, phasediff_output)
        make_config(solint, ms)
        make_selfcal_script(ms)

        tasks = ['mkdir -p '+sourceid+'_selfcal',
                 'mv '+ms+'.config.txt '+sourceid+'_selfcal',
                 'mv '+ms+' '+sourceid+'_selfcal',
                 'mv selfcal_script.sh '+sourceid+'_selfcal']
        os.system(' && '.join(tasks))
    print("---RUN---\nfor P in P?????; do cd $P && sbatch selfcal_script.sh && cd ../; done")
