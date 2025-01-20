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
#SBATCH -t 24:00:00

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
    fulltime = np.max(time)-np.min(time)

    # solint in minutes
    solint_scalarphase_1 = min(max(deltime/60, np.sqrt(solint)), 3)
    solint_scalarphase_2 = min(max(deltime/60, np.sqrt(1.5*solint)), 5)
    solint_scalarphase_3 = min(max(deltime/60, np.sqrt(6*solint)), 5)

    solint_complexgain_1 = max(25.0, 45*solint)
    solint_complexgain_2 = 1.5 * solint_complexgain_1

    cg_cycle_1 = 3
    if solint_complexgain_1/60 > 8:
        cg_cycle_1 = 999
    elif solint_complexgain_1/60 > 5:
        solint_complexgain_1 = 480.
    elif solint_complexgain_1/60 > 3:
        solint_complexgain_1 = 240.

    cg_cycle_2 = 4
    if solint_complexgain_2/60 > 5:
        cg_cycle_1 = 999
    elif solint_complexgain_2/60 > 3:
        solint_complexgain_2 = 240.

    soltypecycles_list = f'[0,0,2,{cg_cycle_1},{cg_cycle_2}]'
    smoothnessreffrequency_list = "[120.0,120.0,120.0,0.0,0.0]"
    smoothnessspectralexponent_list = "[-1.0,-1.0,-1.0,-1.0,-1.0]"
    antennaconstraint_list = "[None,None,'alldutch',None,None]"
    soltype_list = "['scalarphase','scalarphase','scalarphase','scalarcomplexgain','scalarcomplexgain']"
    solint_list = f"['{int(solint_scalarphase_1 * 60)}s','{int(solint_scalarphase_2 * 60)}s','{int(solint_scalarphase_3 * 60)}s','{int(solint_complexgain_1*60)}s','{int(solint_complexgain_2*60)}s']"
    stop = 10
    imsize = 2048
    avgstep = 1


    if 'ILTJ161212.29+552303.8' in ms: #TODO: SPECIAL CASE!
        solint_list = f"['{int(solint_scalarphase_1 * 60)}s','{int(solint_scalarphase_2 * 60)}s','{int(solint_scalarphase_3 * 60)}s','900s','{int(solint_complexgain_2 * 60)}s']"
        uvmin=50000
        smoothness_phase = 10.0
        smoothness_complex = 10.0
        smoothnessconstraint_list = f"[{smoothness_phase},{smoothness_phase*1.5},{smoothness_phase*1.5},{smoothness_complex},{smoothness_complex+5.0}]"
        resetsols_list = "['alldutchandclosegerman','alldutch',None,'alldutch','coreandallbutmostdistantremotes']"
        antennaconstraint_list = "[None,None,'alldutch',None,None]"
        stop = 20

    elif solint<0.05:
        uvmin=40000
        smoothness_phase = 8.0
        smoothness_complex = 10.0
        smoothnessconstraint_list = f"[{smoothness_phase},{smoothness_phase*1.5},{smoothness_phase*1.5},{smoothness_complex},{smoothness_complex+5.0}]"
        resetsols_list = "['alldutchandclosegerman','alldutch',None,'alldutch','coreandfirstremotes']"

    elif solint<0.1:
        uvmin=35000
        smoothness_phase = 10.0
        smoothness_complex = 10.0
        smoothnessconstraint_list = f"[{smoothness_phase},{smoothness_phase*1.25},{smoothness_phase*1.25},{smoothness_complex},{smoothness_complex+5.0}]"
        resetsols_list = "['alldutchandclosegerman','alldutch',None,'alldutch','coreandallbutmostdistantremotes']"

    elif solint<1:
        uvmin=30000
        smoothness_phase = 10.0
        smoothness_complex = 12.5
        smoothnessconstraint_list = f"[{smoothness_phase},{smoothness_phase*1.25},{smoothness_phase*1.25},{smoothness_complex},{smoothness_complex+5.0}]"
        resetsols_list = "['alldutchandclosegerman','alldutch',None,'alldutch','coreandallbutmostdistantremotes']"

    elif solint<2.5:
        uvmin=25000
        smoothness_phase = 10.0
        smoothness_complex = 15.0
        smoothnessconstraint_list = f"[{smoothness_phase},{smoothness_phase*1.25},{smoothness_phase*1.25},{smoothness_complex},{smoothness_complex+10.0}]"
        resetsols_list = "['alldutchandclosegerman','alldutch',None,'alldutch','coreandallbutmostdistantremotes']"

    elif solint<4:
        uvmin=25000
        smoothness_phase = 10.0
        smoothness_complex = 20.0
        smoothnessconstraint_list = f"[{smoothness_phase},{smoothness_phase*1.25},{smoothness_phase*1.25},{smoothness_complex},{smoothness_complex+5.0}]"
        resetsols_list = "['alldutchandclosegerman','alldutch',None,'alldutchandclosegerman','alldutch']"

    elif solint<15:
        uvmin=20000
        soltypecycles_list = f'[0,0,{cg_cycle_1}]'
        smoothnessconstraint_list = f"[10.0,15.0,25.0]"
        smoothnessreffrequency_list = "[120.0,120.0,0.0]"
        smoothnessspectralexponent_list = "[-1.0,-1.0,-1.0]"
        solint_list = f"['{int(solint_scalarphase_1*60)}s','{int(solint_scalarphase_2*60)}s','{int(solint_complexgain_1*60)}s']"
        soltype_list = "['scalarphase','scalarphase','scalarcomplexgain']"
        resetsols_list = "['alldutchandclosegerman','alldutch','alldutch']"
        antennaconstraint_list = "[None,None,None]"

    else:
        uvmin=20000
        soltypecycles_list = f'[0,0]'
        smoothnessconstraint_list = f"[15.0,20.0]"
        smoothnessreffrequency_list = "[120.0,120.0]"
        smoothnessspectralexponent_list = "[-1.0,-1.0]"
        solint_list = f"['{int(solint_scalarphase_1*60)}s','{int(solint_scalarphase_2*60)}s']"
        soltype_list = "['scalarphase','scalarphase']"
        resetsols_list = "['alldutchandclosegerman','alldutch']"
        antennaconstraint_list = "[None,None]"


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
imsize                          = {imsize}
resetsols_list                  = {resetsols_list}
antennaconstraint_list          = {antennaconstraint_list}
paralleldeconvolution           = 1024
targetcalILT                    = "scalarphase"
stop                            = {stop}
compute_phasediffstat           = True
get_diagnostics                 = True
parallelgridding                = 6
channelsout                     = 24
fitspectralpol                  = 9
"""
    if avgstep>1:
        config+=f"""avgtimestep                     = {avgstep}
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
