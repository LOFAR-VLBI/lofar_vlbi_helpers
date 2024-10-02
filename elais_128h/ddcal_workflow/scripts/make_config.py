#!/usr/bin/env python3
# -*- coding: utf-8 -*-

__author__ = "Jurjen de Jong"

from argparse import ArgumentParser
import numpy as np
import pandas as pd
import casacore.tables as ct


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
    solint_scalarphase_1 = min(max(deltime/60, np.sqrt(solint)), 3)
    solint_scalarphase_2 = min(max(deltime/60, np.sqrt(1.5*solint)), 5)
    solint_scalarphase_3 = min(max(1, 2*np.sqrt(solint)), 10)

    solint_complexgain_1 = max(18.0, 20*solint)

    # start ampsolve
    cg_cycle = 3

    if solint_complexgain_1/60 > 4:
        cg_cycle = 999
    elif solint_complexgain_1/60 > 3:
        solint_complexgain_1 = 240.

    smoothness_phase = 8.0

    soltypecycles_list = f'[0,0,0,{cg_cycle}]'
    soltype_list = "['scalarphase','scalarphase','scalarphase','scalarcomplexgain']"
    smoothnessreffrequency_list = "[120.0,120.0,120.0,0.0]"
    smoothnessspectralexponent_list = "[-1.0,-1.0,-1.0,-1.0]"
    solint_list = f"['{int(solint_scalarphase_1*60)}s','{int(solint_scalarphase_2*60)}s','{int(solint_scalarphase_3*60)}s','{int(solint_complexgain_1*60)}s']"

    # adjusted settings based on solint/phasediff score
    if solint<0.3:
        uvmin=60000
        resetsols_list = "['alldutchandclosegerman','alldutch','core','core']"
        smoothness_complex = 8.0
        smoothnessconstraint_list = f"[{smoothness_phase},{smoothness_phase},{smoothness_phase * 1.5},{smoothness_complex}]"


    elif solint<1:
        uvmin=45000
        resetsols_list = "['alldutchandclosegerman','alldutch','coreandfirstremotes','coreandfirstremotes]"
        smoothness_complex = 8.0
        smoothnessconstraint_list = f"[{smoothness_phase},{smoothness_phase},{smoothness_phase * 1.5},{smoothness_complex}]"


    elif solint<3:
        uvmin=30000
        resetsols_list = "['alldutchandclosegerman','alldutch','coreandallbutmostdistantremotes','coreandallbutmostdistantremotes']"
        smoothness_complex = 10.0
        smoothnessconstraint_list = f"[{smoothness_phase},{smoothness_phase},{smoothness_phase * 1.5},{smoothness_complex}]"


    else:
        uvmin=20000
        soltypecycles_list = f'[0,0,{cg_cycle}]'
        soltype_list = "['scalarphase','scalarphase','scalarcomplexgain']"
        smoothness_complex = 12.5
        smoothnessconstraint_list = f"[{smoothness_phase},{smoothness_phase},{smoothness_complex}]"
        smoothnessreffrequency_list = "[120.0,120.0,0.0]"
        smoothnessspectralexponent_list = "[-1.0,-1.0,-1.0]"
        solint_list = f"['{int(solint_scalarphase_1*60)}s','{int(solint_scalarphase_2*60)}s','{int(solint_complexgain_1*60)}s']"
        resetsols_list = "['alldutchandclosegerman','alldutch','alldutch']"


    script=f"""imagename                       = dd_selfcal
phaseupstations                 = 'core'
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
targetcalILT                    ='scalarphase'
stop                            = 7
flagtimesmeared                 = True
compute_phasediffstat           = True
get_diagnostics                 = True
parallelgridding                = 6
"""

    if solint_scalarphase_1*60>64:
        script+='\navgtimestep                     = 64s'

    # write to file
    with open(ms+".config.txt", "w") as f:
        f.write(script)


def get_solint(ms, phasediff_output):
    """
    Get solution interval
    Args:
        ms: MeasurementSet
        phasediff_output: phasediff CSV output

    Returns: solution interval in minutes

    """

    phasediff = pd.read_csv(phasediff_output)
    sourceid = ms.split("_")[0]

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
