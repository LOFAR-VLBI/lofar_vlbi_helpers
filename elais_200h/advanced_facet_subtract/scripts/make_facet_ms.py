#!/usr/bin/env python3
# -*- coding: utf-8 -*-

__author__ = "Jurjen de Jong"

from argparse import ArgumentParser
import os
import re
import sys

from casacore.tables import table, taql
import numpy as np
import pandas as pd
import tables

dtype = np.complex64

def interpolate(from_ms, to_ms, column: str = "MODEL_DATA", outdir: str = "."):
    """
    Interpolate the given column from an input MeasurementSet to an output MeasurementSet.

    Parameters:
        from_ms (str): Path (or identifier) of the input MeasurementSet.
        to_ms (str): Path (or identifier) of the output MeasurementSet.
        column (str): The name of the column to interpolate.
        outdir (str): Path to write log files to

    """

    with table(to_ms, readonly=False, ack=False) as ts:
        colnames = ts.colnames()

        if column not in colnames:
            # get column description from DATA
            desc = ts.getcoldesc('DATA')
            # create output column
            print('Create ' + column)
            desc['name'] = column
            # create template for output column
            ts.addcols(desc)

        else:
            print(column, ' already exists')

    command = ['DP3',
               f'msin={to_ms}',
               f'msout.datacolumn={column}',
               f'msout=.',
               'msout.storagemanager=dysco',
               'msout.storagemanager.databitrate=6',
               'msout.storagemanager.weightbitrate=12',
               'transfer.type=transfer',
               'transfer.data=True',
               f'transfer.source_ms={from_ms}',
               f'transfer.datacolumn={column}',
               f'steps=[transfer]']

    os.system(' '.join(command) + f' > {outdir}/transfer.log')


def make_facet_data(ms: str = None, phaseshift: str = None, freqavg: str = None,
            timeres: str = None, applycal_h5: str = None, dirname: str = None, outdir: str = "."):
    """
    Run DP3 command to split out facet. This step assumes the solutions that are applied to be scalar.

    :param ms: MeasurementSet of the output
    :param phaseshift: do phase shift to specific center
    :param freqavg: frequency averaging
    :param timeres: time resolution in seconds
    :param applycal_h5: applycal solution file
    :param dirname: direction name from h5parm
    :param outdir: Path to write log files to
    """

    steps = []

    msout = f"facet_{dirname.replace("Dir","")}_{ms.split("/")[-1]}"

    command = ['DP3',
               f'msin={ms}',
               'msin.datacolumn=DATA',
               f'msout={msout}',
               'msout.storagemanager=dysco',
               'msout.storagemanager.databitrate=6',
               'msout.storagemanager.weightbitrate=12']

    # 1) PHASESHIFT
    phasecenter = phaseshift.replace('[', '').replace(']', '').split(',')
    phasecenter = f'[{phasecenter[0]},{phasecenter[1]}]'
    steps.append('ps')
    command += ['ps.type=phaseshifter',
                'ps.phasecenter=' + phasecenter]

    # 2) AVERAGING
    steps.append('avg')
    command += ['avg.type=averager']
    if freqavg is not None:
        if str(freqavg).isdigit() or not str(freqavg)[-1].isalpha():
            command += [f'avg.freqstep={int(freqavg)}']
        else:
            command += [f'avg.freqresolution={freqavg}']
    if timeres is not None:
        command += [f'avg.timeresolution={timeres}']

    # 3) APPLYCAL
    ac_count = 0
    T = tables.open_file(applycal_h5)
    for corr in T.root.sol000._v_groups.keys():
        if 'phase' in corr or 'amp' in corr:
            command += [f'ac{ac_count}.type=applycal',
                        f'ac{ac_count}.parmdb={applycal_h5}',
                        f'ac{ac_count}.correction={corr}']
            if phaseshift is not None and dirname is not None:
                command += [f'ac{ac_count}.direction=' + dirname]
            steps.append(f'ac{ac_count}')
            ac_count += 1
    T.close()

    command += ['steps=' + str(steps).replace(" ", "").replace("\'", "")]

    os.system(' '.join(command) + f' > {outdir}/DP3.log')

    # Beam will be applied in a later concat step to reduce compute costs

    return msout


def get_largest_divider(inp, integer):
    """
    Get largest divider

    :param inp: input number
    :param max: max divider

    :return: largest divider from inp bound by max
    """

    for r in range(integer+1)[::-1]:
        if inp % r == 0:
            return r
    sys.exit("ERROR: code should not arrive here.")


def parse_history(ms, hist_item):
    """
    Grep specific history item from MS

    :param ms: MeasurementSet
    :param hist_item: history item

    :return: parsed string
    """

    hist = os.popen('taql "SELECT * FROM ' + ms + '::HISTORY" | grep ' + hist_item).read().split(' ')
    for item in hist:
        if hist_item in item and len(hist_item) <= len(item):
            return item
    print('WARNING:' + hist_item + ' not found')
    return None


def get_time_preavg_factor(ms: str = None):
    """
    Get time pre-averaging factor (given by demixer.timestep)

    Args:
        ms (str): MeasurementSet

    Returns:
        int: averaging integer
    """

    parse_str = "demixer.timestep="
    parsed_history = parse_history(ms, parse_str)
    avg_num = re.findall(r'\d+', parsed_history.replace(parse_str, ''))[0]
    if avg_num.isdigit():
        factor = int(float(avg_num))
        if factor != 1:
            print("WARNING: " + ms + " time has been pre-averaged with factor " + str(
                factor) + ". This might cause stronger time smearing effects in your final image.")
        return factor
    elif type(avg_num)==float:
        factor = float(avg_num)
        print("WARNING: parsed factor in " + ms + " is not a digit but a float")
        return factor
    else:
        print("WARNING: parsed factor in " + ms + " is not a float or digit")
        return None


def get_facet_info(polygon_info_file, ms, polygon_region):
    """
    Extract facet information from polygon metadata and a MeasurementSet.

    Args:
        polygon_info_file (str): Path to the CSV file with polygon averaging and names.
        ms (str): Path to the MeasurementSetMeasurementSet.
        polygon_region (str): Name of the polygon region (e.g., DS9 region path).

    Returns:
        tuple: (phasecentre, freq_avg, time_avg, direction_name)
    """

    # Load polygon info CSV
    polygon_info = pd.read_csv(polygon_info_file)

    # Get number of channels from SPECTRAL_WINDOW
    with table(ms + "::SPECTRAL_WINDOW", ack=False) as t:
        nchan = len(t.getcol("CHAN_FREQ")[0])

    # Get time resolution from MS
    with table(ms, ack=False) as t:
        times = np.unique(t.getcol("TIME"))
        time_delta = abs(times[1] - times[0]) if len(times) > 1 else 1.0

    # Extract polygon row matching the given region file name
    region_file = polygon_region.split('/')[-1]
    polygon = polygon_info.loc[polygon_info.polygon_file == region_file]

    if polygon.empty:
        raise ValueError(f"No entry found for region '{region_file}' in {polygon_info_file}")

    # Phase centre: prefer 'poly_center' but fall back to 'dir'
    if 'poly_center' in polygon and pd.notna(polygon['poly_center'].values[0]):
        phasecentre = polygon['poly_center'].values[0]
    else:
        print('WARNING: No poly_center in polygon_info.csv; using dir instead.')
        phasecentre = polygon['dir'].values[0]

    # Frequency averaging
    avg = int(polygon['avg'].values[0])
    freq_avg = get_largest_divider(nchan, avg)

    # Time averaging, accounting for pre-averaging if present
    try:
        time_preavg = get_time_preavg_factor(ms)
        time_avg = int(avg // time_preavg * time_delta)
    except Exception:
        time_avg = int(avg * time_delta)

    direction_name = polygon['dir_name'].values[0]

    return phasecentre, freq_avg, time_avg, direction_name


def copy_data(dat, to):
    os.system(f"rsync -avH --no-implied-dirs --copy-links {dat} {to}")


def parse_args():
    """
    Parse input arguments
    """

    parser = ArgumentParser(description='Split out facets after interpolating model data to data.')
    parser.add_argument('--from_ms', help='MS input from where to interpolate', required=True)
    parser.add_argument('--to_ms', help='MS to interpolate to (your output set)', required=True)
    parser.add_argument('--polygon', help='Polygon region', required=True)
    parser.add_argument('--h5parm', help='Multi-dir h5 solutions', required=True)
    parser.add_argument('--polygon_info', help='Polygon information')
    parser.add_argument('--cleanup', action='store_true', help='rm -rf on input MS and *.dat to save storage')
    parser.add_argument('--tmp', typ=str, help='Temporary directory to run I/O heavy jobs', default='.')

    return parser.parse_args()


def main():
    """
    Main script
    """

    args = parse_args()

    if args.tmp != '.':
        rundir = args.tmp
        copy_data(args.to_ms.split('/')[-1], rundir) # MS
        os.system(f"rm -rf {args.to_ms}") # Delete local MS to free up space
        outdir = os.getcwd()
        os.chdir(rundir)
    else:
        outdir = '.'

    # Interpolate flags
    print(f'Interpolate from {args.from_ms} to {args.to_ms}')
    facet_number = args.polygon.split('/')[-1].replace('.reg', '').replace('poly_', '')
    facet_column = f"POLY_{facet_number}"
    interpolate(args.from_ms, args.to_ms, facet_column, outdir)

    phasecentre, freqavg, timeres, dirname = get_facet_info(args.polygon_info, args.to_ms, args.polygon)

    # Subtraction
    print(f"SUBTRACT ==> DATA = DATA - {facet_column}")
    taql(f"UPDATE {args.to_ms} SET DATA = DATA - {facet_column}")

    # Make facet data
    print("Run DP3")
    make_facet_data(args.to_ms, phasecentre, freqavg, timeres, args.h5parm, dirname, outdir)

    # Copy data back to output directory
    if args.tmp != '.':
        copy_data('facet_*.ms', outdir)

    # Delete a copy to save storage
    if args.cleanup:
        print("Cleanup...")
        os.system(f"rm -rf {args.to_ms}")
        os.system(f'rm *.dat')


if __name__ == '__main__':
    main()
