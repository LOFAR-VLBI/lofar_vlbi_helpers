#!/usr/bin/env python3
# -*- coding: utf-8 -*-

__author__ = "Jurjen de Jong"

from argparse import ArgumentParser
import numpy as np
import pandas as pd
import casacore.tables as ct
import re


def parse_source_id(inp_str: str = None):
    """
    Parse ILTJ... source_id string

    Args:
        inp_str: ILTJ source_id

    Returns: parsed output

    """

    parsed_inp = re.findall(r'ILTJ\d+\..\d+\+\d+.\d+', inp_str)[0]

    return parsed_inp


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
    solint_scalarphase_1 = min(max(deltime/60, np.sqrt(0.5*solint)), 3)
    solint_scalarphase_2 = min(max(deltime/60, np.sqrt(1.25*solint)), 5)
    solint_scalarphase_3 = min(max(deltime/60, np.sqrt(2*solint)), 5)

    solint_complexgain_1 = max(25.0, 40*solint)
    solint_complexgain_2 = 1.5 * solint_complexgain_1

    cg_cycle_1 = 3
    if solint_complexgain_1/60 > 6:
        cg_cycle_1 = 999
    elif solint_complexgain_1/60 > 3:
        solint_complexgain_1 = 240.

    cg_cycle_2 = 4
    if solint_complexgain_2/60 > 6:
        cg_cycle_2 = 999
    elif solint_complexgain_2/60 > 3:
        solint_complexgain_2 = 240.

    soltypecycles_list = f'[0,0,1,{cg_cycle_1},{cg_cycle_2}]'
    smoothnessreffrequency_list = "[120.0,120.0,120.0,0.0,0.0]"
    smoothnessspectralexponent_list = "[-1.0,-1.0,-1.0,-1.0,-1.0]"
    antennaconstraint_list = "[None,None,None,None,None]"
    soltype_list = "['scalarphase','scalarphase','scalarphase','scalarcomplexgain','scalarcomplexgain']"
    solint_list = f"['{int(solint_scalarphase_1 * 60)}s','{int(solint_scalarphase_2 * 60)}s','{int(solint_scalarphase_3 * 60)}s','{int(solint_complexgain_1*60)}s','{int(solint_complexgain_2*60)}s']"
    stop = 10
    imsize = 2048
    if solint_scalarphase_1 * 60 > deltime * 2:
        avgstep = 2
    else:
        avgstep = 1

    if solint<0.05:
        uvmin=45000
        smoothness_phase = 8.0
        smoothness_complex = 10.0
        smoothnessconstraint_list = f"[{smoothness_phase},{smoothness_phase*1.5},{smoothness_phase*1.5},{smoothness_complex},{smoothness_complex+5.0}]"
        resetsols_list = "['alldutchandclosegerman','alldutch','coreandfirstremotes','alldutch','coreandfirstremotes']"

    elif solint<0.1:
        uvmin=40000
        smoothness_phase = 10.0
        smoothness_complex = 10.0
        smoothnessconstraint_list = f"[{smoothness_phase},{smoothness_phase*1.25},{smoothness_phase*1.25},{smoothness_complex},{smoothness_complex+5.0}]"
        resetsols_list = "['alldutchandclosegerman','alldutch','coreandallbutmostdistantremotes','alldutch','coreandallbutmostdistantremotes']"

    elif solint<1:
        uvmin=35000
        smoothness_phase = 10.0
        smoothness_complex = 12.5
        smoothnessconstraint_list = f"[{smoothness_phase},{smoothness_phase*1.25},{smoothness_phase*1.25},{smoothness_complex},{smoothness_complex+5.0}]"
        resetsols_list = "['alldutchandclosegerman','alldutch','coreandallbutmostdistantremotes','alldutch','coreandallbutmostdistantremotes']"

    elif solint<2.5:
        uvmin=30000
        smoothness_phase = 10.0
        smoothness_complex = 15.0
        smoothnessconstraint_list = f"[{smoothness_phase},{smoothness_phase*1.25},{smoothness_phase*1.25},{smoothness_complex},{smoothness_complex+10.0}]"
        resetsols_list = "['alldutchandclosegerman','alldutch','coreandallbutmostdistantremotes','alldutch','coreandallbutmostdistantremotes']"

    elif solint<4:
        uvmin=25000
        smoothness_phase = 10.0
        smoothness_complex = 20.0
        soltypecycles_list = f'[0,0,{cg_cycle_1},{cg_cycle_2}]'
        smoothnessconstraint_list = f"[{smoothness_phase},{smoothness_phase*1.25},{smoothness_complex},{smoothness_complex+5.0}]"
        smoothnessreffrequency_list = "[120.0,120.0,0.0,0.0]"
        smoothnessspectralexponent_list = "[-1.0,-1.0,-1.0,-1.0]"
        solint_list = f"['{int(solint_scalarphase_1*60)}s','{int(solint_scalarphase_2*60)}s','{int(solint_complexgain_1*60)}s','{int(solint_complexgain_2*60)}s']"
        soltype_list = "['scalarphase','scalarphase','scalarcomplexgain','scalarcomplexgain']"
        resetsols_list = "['alldutchandclosegerman','alldutch','alldutchandclosegerman','alldutch']"
        antennaconstraint_list = "[None,None,None,None]"

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
channelsout                     = 12
fitspectralpol                  = 5
"""
    if avgstep>1:
        config+=f"""avgtimestep                     = {avgstep}
"""

    # write to file
    with open(ms+".config.txt", "w") as f:
        f.write(config)


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


def parse_args():
    """
    Command line argument parser

    Returns: parsed arguments
    """

    parser = ArgumentParser(description='Make config for facetselfcal international DD solves')
    parser.add_argument('--ms', type=str, help='MeasurementSet')
    parser.add_argument('--phasediff_output', type=str, help='Phasediff CSV output')
    return parser.parse_args()


def main():
    """
    Main function
    """

    args = parse_args()

    solint = get_solint(args.ms, args.phasediff_output)
    make_config(solint, args.ms)


if __name__ == "__main__":
    main()
