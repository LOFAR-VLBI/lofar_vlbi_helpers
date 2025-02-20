#!/usr/bin/env python3
# -*- coding: utf-8 -*-

__author__ = "Jurjen de Jong"

from argparse import ArgumentParser
import numpy as np
from casacore.tables import table
from numba import njit, set_num_threads, prange
from joblib import Parallel, delayed
import os
from sys import stdout
import tables
import sys
import pandas as pd
import re


def print_progress_bar(index, total, bar_length=50):
    """
    Prints a progress bar.

    :param:
        - index: the current index (0-based) in the iteration.
        - total: the total number of indices.
        - bar_length: the character length of the progress bar (default 50).
    """

    percent_complete = (index + 1) / total
    filled_length = int(bar_length * percent_complete)
    bar = "█" * filled_length + '-' * (bar_length - filled_length)
    stdout.write(f'\rProgress: |{bar}| {percent_complete * 100:.1f}% Complete')
    stdout.flush()  # Important to ensure the progress bar is updated in place

    # Print a new line on completion
    if index == total - 1:
        print()


def make_ant_pairs(n_ant, n_time):
    """
    Make ANTENNA1 and ANTENNA2 pair arrays for an array with M antennas over N time slots.

    :param:
        - n_ant: Number of antennas in the array.
        - n_time: Number of time slots.

    :return:
        - ANTENNA1
        - ANTENNA2
    """

    # Generate all unique pairs of antennas for one time slot
    antenna_pairs = [(i, j) for i in range(n_ant) for j in range(i + 1, n_ant)]

    # Expand the pairs across n_time time slots
    antenna1 = np.array([pair[0] for pair in antenna_pairs] * n_time)
    antenna2 = np.array([pair[1] for pair in antenna_pairs] * n_time)

    return antenna1, antenna2


def add_axis(arr, ax_size):
    """
    Add ax dimension with a specific size

    :param:
        - arr: numpy array
        - ax_size: axis size

    :return:
        - output with new axis dimension with a particular size
    """

    or_shape = arr.shape
    new_shape = list(or_shape) + [ax_size]
    return np.repeat(arr, ax_size).reshape(new_shape)


@njit
def find_nearest_index(ref, value):
    """
    Given a sorted 1D array 'ref', find the index of the element nearest to 'value' using a binary search.
    """
    low = 0
    high = len(ref)
    while low < high:
        mid = (low + high) // 2
        if ref[mid] < value:
            low = mid + 1
        else:
            high = mid
    idx = low
    if idx >= len(ref):
        idx = len(ref) - 1
    if idx > 0:
        if abs(ref[idx - 1] - value) < abs(ref[idx] - value):
            idx = idx - 1
    return idx


@njit(parallel=True)
def interpolate_data_single_baseline(time_in, freqs_in, data_in, time_out, freqs_out):
    """
    Standard nearest-neighbor interpolation.

    Parameters:
      time_in, freqs_in : input time and frequency
      data_in : input data with shape (n_time_in, n_freq_in, 4)
      time_out, freqs_out : output time and frequency

    Returns:
      new_data : 3D array of shape (len(time_out), len(freqs_out), 4)
    """

    n_time_out = time_out.shape[0]
    n_freq_out = freqs_out.shape[0]
    n_pol = data_in.shape[2]
    new_data = np.empty((n_time_out, n_freq_out, n_pol), dtype=data_in.dtype)

    for i in prange(n_time_out):
        t_val = time_out[i]
        t_idx = find_nearest_index(time_in, t_val)
        for j in range(n_freq_out):
            f_val = freqs_out[j]
            f_idx = find_nearest_index(freqs_in, f_val)
            for p in range(n_pol):
                new_data[i, j, p] = data_in[t_idx, f_idx, p]
    return new_data


@njit(parallel=True)
def interpolate_data_single_baseline_stokes_i(time_in, freqs_in, data_in, time_out, freqs_out):
    """
    Nearest-neighbor interpolation in Stokes I

    Parameters:
      time_in, freqs_in : input time and frequency
      data_in : input data with shape (n_time_in, n_freq_in, 4)
      time_out, freqs_out : utput time and frequency

    Returns:
      new_data : output data with shape (len(time_out), len(freqs_out))
    """

    n_time_out = time_out.shape[0]
    n_freq_out = freqs_out.shape[0]
    new_data = np.empty((n_time_out, n_freq_out), dtype=data_in.dtype)

    for i in prange(n_time_out):
        t_val = time_out[i]
        t_idx = find_nearest_index(time_in, t_val)
        for j in range(n_freq_out):
            f_val = freqs_out[j]
            f_idx = find_nearest_index(freqs_in, f_val)
            new_data[i, j] = data_in[t_idx, f_idx]
    return new_data


@njit(parallel=True)
def compute_stokes_I(data_in):
    """
    Compute Stokes I = (XX + YY) / 2

    Parameters:
      data_in : input data

    Returns:
      Output data with shape (n_time, n_freq) with the computed Stokes I.
    """

    n_time, n_freq, n_pol = data_in.shape
    # Create an output array with the same time and frequency dimensions.
    result = np.empty((n_time, n_freq), dtype=data_in.dtype)

    for i in prange(n_time):
        for j in range(n_freq):
            result[i, j] = (data_in[i, j, 0] + data_in[i, j, n_pol - 1]) / 2
    return result


def process_baseline(baseline, from_ms, out_times, out_ant1, out_ant2,
                     freqs_in, freqs_out, column, stokes_i, data_out):
    """
    Process a single baseline:
      - Identify output rows corresponding to the baseline.
      - Open the input measurement set for that baseline.
      - Interpolate the data.

    If no rows are found with the given antenna order, it tries the swapped order (normally not an issue..).
    Returns a tuple (mask, new_data) where 'mask' selects the output rows.
    """

    ant1, ant2 = baseline
    mask = (out_ant1 == ant1) & (out_ant2 == ant2)
    if not np.any(mask):
        return mask, None

    time_out = out_times[mask]

    # Helper function to perform the query.
    def query_ms(query_str):
        with table(from_ms, ack=False) as t_in:
            with t_in.query(query_str) as sub_in:
                time_in = sub_in.getcol("TIME")
                data_in = sub_in.getcol(column)
                if stokes_i:
                    data_in = compute_stokes_I(data_in)
        return time_in, data_in

    # First try the query with the output order.
    query_str = f"ANTENNA1={ant1} AND ANTENNA2={ant2}"
    try:
        time_in, data_in = query_ms(query_str)
    except Exception:
        time_in = None

    # If no rows are returned (or time_in is empty), try the reversed order.
    if time_in is None or time_in.size == 0:
        query_str = f"ANTENNA1={ant2} AND ANTENNA2={ant1}"
        try:
            time_in, data_in = query_ms(query_str)
        except Exception:
            return mask, None

    # Now perform the interpolation.
    if stokes_i:
        new_data = interpolate_data_single_baseline_stokes_i(time_in, freqs_in, data_in, time_out, freqs_out)
    else:
        new_data = interpolate_data_single_baseline(time_in, freqs_in, data_in, time_out, freqs_out)

    data_out[mask, ...] = new_data

    return


@njit(parallel=True)
def subtract_arrays(a, b):
    result = np.empty_like(a)
    for i in prange(a.size):
        result.flat[i] = a.flat[i] - b.flat[i]
    return result


def interpolate(from_ms, to_ms, column: str = "MODEL_DATA", stokes_i: bool = False, tmpdir: str = './', subtract: bool = False):
    """
    Interpolate the given column from an input measurement set to an output measurement set.

    Parameters:
        from_ms (str): Path (or identifier) of the input measurement set.
        to_ms (str): Path (or identifier) of the output measurement set.
        column (str): The name of the column to interpolate.
        stokes_i: Stokes I only interpolation (XX+YY)/2 and XY=YX=0
        tmpdir: temporary directory for memmap storage
        subtract: Subtraction DATA-column in output
    """

    with table(to_ms, ack=False) as t_out:
        # Retrieve frequency axes from the spectral window subtables.
        with table(from_ms + "::SPECTRAL_WINDOW", ack=False) as spw_in:
            freqs_in = spw_in.getcol("CHAN_FREQ")[0]
        with table(to_ms + "::SPECTRAL_WINDOW", ack=False) as spw_out:
            freqs_out = spw_out.getcol("CHAN_FREQ")[0]

        # Get time and antenna info from the output MS
        print("Get TIME, ANTENNA1, ANTENNA2 columns ...")
        out_times = t_out.getcol("TIME")
        out_ant1 = t_out.getcol("ANTENNA1")
        out_ant2 = t_out.getcol("ANTENNA2")

        # Unique baselines from the output.
        baselines = np.unique(np.vstack([out_ant1, out_ant2]).T, axis=0)

        n_rows = out_times.shape[0]
        n_freq_out = freqs_out.shape[0]

        # Create a temporary memmap for the global output data.
        tmp_filename = os.path.join(tmpdir, f"{column}.dat")

        if stokes_i:
            shape = (n_rows, n_freq_out)
        else:
            shape = (n_rows, n_freq_out, 4)

        print(f"Make memmap {tmp_filename} ...")
        global_data = np.memmap(tmp_filename, dtype=np.complex64, mode='w+', shape=shape)
        global_data[:] = 0

        # Process each baseline in parallel.
        print("Interpolate data for all baselines ...")
        Parallel(n_jobs=-1, verbose=10)(
            delayed(process_baseline)(
                baseline, from_ms, out_times, out_ant1, out_ant2, freqs_in, freqs_out, column, stokes_i, global_data
            ) for baseline in baselines
        )

        print("Flush data ...")
        global_data.flush()


    # Write the updated column from the memmap back to the output measurement set.
    print(f"Write results to {column} in chunks...")
    with table(to_ms, ack=False, readonly=False) as t_out:

        # If the column doesn't exist in the output MS, add it.
        if not subtract:
            if column not in t_out.colnames():
                with table(from_ms, ack=False) as t_in:
                    desc = t_in.getcoldesc(column)
                desc['name'] = column
                t_out.addcols(desc)
            else:
                print(column, 'already exists (will overwrite)')

        n_rows = global_data.shape[0]
        chunk_size = min(200000, n_rows)
        if subtract:
            print(f"SUBTRACT ==> DATA = DATA - {column}")
        for start in range(0, n_rows, chunk_size):
            print_progress_bar(start, n_rows)
            end = min(start + chunk_size, n_rows)
            chunk = np.array(global_data[start:end, ...])
            if stokes_i:
                chunk = add_axis(chunk, 4)
                chunk[..., 1] = 0
                chunk[..., 2] = 0
            if subtract:
                chunk = subtract_arrays(t_out.getcol("DATA", startrow=start, nrow=chunk_size), chunk)
                t_out.putcol('DATA', chunk, startrow=start, nrow=chunk_size)
            else:
                t_out.putcol(column, chunk, startrow=start, nrow=chunk_size)
        print_progress_bar(n_rows, n_rows)
    # Clean up the temporary memmap file.
    try:
        os.remove(tmp_filename)
    except Exception:
        pass
    print(f"\nInterpolation Finished ==> {to_ms}::{column}\n")


def run_DP3(ms: str = None, phaseshift: str = None, freqavg: str = None,
            timeres: str = None, applycal_h5: str = None, dirname: str = None):
    """
    Run DP3 command, assuming scalar solutions!

    :param ms: MeasurementSet of the output
    :param phaseshift: do phase shift to specific center
    :param freqavg: frequency averaging
    :param timeres: time resolution in seconds
    :param applycal_h5: applycal solution file
    :param dirname: direction name from h5parm
    """

    steps = []

    msout = f"facet_{dirname.replace("Dir","")}_{ms.split("/")[-1]}"

    command = ['DP3',
               f'msin={ms}'
               'msin.missingdata=True',
               'msin.datacolumn=DATA',
               'msin.orderms=False',
               f'msout={msout}',
               'msout.storagemanager=dysco',
               'msout.storagemanager.databitrate=8',
               'msout.storagemanager.weightbitrate=10']

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

    # 3) APPLY BEAM
    steps.append('beam1')
    command += ['beam1.type=applybeam',
                'beam1.updateweights=True',
                'beam1.direction=[]']

    # 4) APPLYCAL
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

    os.system(' '.join(command))

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

    :param ms: measurement set
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

    :param ms: measurement set

    :return: averaging integer
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
    Get facet information from polygon splitting.

    Args:
        polygon_info_file: CSV with polygon averaging and names
        ms: MeasurementSet from output
        polygon_region: Polygon region name

    Returns: phase centre, averaging, and direction name
    """


    # Find and read the file
    polygon_info = pd.read_csv(polygon_info_file)

    with table(ms + "::SPECTRAL_WINDOW", ack=False) as t:
        channum = len(t.getcol("CHAN_FREQ")[0])

    with table(ms, ack=False) as t:
        time = np.unique(t.getcol("TIME"))
        dtime = abs(time[1] - time[0])

    polygon = polygon_info.loc[polygon_info.polygon_file == polygon_region.split('/')[-1]]
    try:
        phasecenter = polygon['poly_center'].values[0]
    except AttributeError:
        print('WARNING: no poly center in polygon_info.csv, use dir instead.')
        phasecenter = polygon['dir'].values[0]
    except KeyError:
        print('WARNING: no poly center in polygon_info.csv, use dir instead.')
        phasecenter = polygon['dir'].values[0]

    avg = int(polygon['avg'].values[0])

    # take only averaging factors that are channum%avg==0
    freqavg = get_largest_divider(channum, avg)

    try:
        # if there is pre averaging done on the ms, we need to take this into account
        timeres = int(avg // get_time_preavg_factor(ms) * dtime)

    except:
        timeres = int(avg * dtime)

    # in case of widefield imaging and stacking multiple nights, you might want to have only even time resolutions
    if timeres % 2 != 0:
        timeres -= 1
        print(f"Time resolution from {timeres + 1} to {timeres}")

    dirname = polygon['dir_name'].values[0]

    return phasecenter, freqavg, timeres, dirname


def parse_args():
    """
    Parse input arguments
    """

    parser = ArgumentParser(description='Interpolate DATA or MODEL_DATA from a specific time/freq resolution to another resolution and apply DP3 to make data smaller.')
    parser.add_argument('--from_ms', help='MS input from where to interpolate', required=True)
    parser.add_argument('--to_ms', help='MS to interpolate to (your output set)', required=True)
    parser.add_argument('--polygon', help='Polygon region', required=True)
    parser.add_argument('--h5parm', help='Multi-dir h5 solutions', required=True)
    parser.add_argument('--polygon_info', help='Polygon information')
    parser.add_argument('--delete_input_ms', action='store_true', help='rm -rf on input MS to save storage')
    return parser.parse_args()


def main():
    """
    Main script
    """

    set_num_threads(max(os.cpu_count() - 1, 1))

    args = parse_args()

    # Interpolate flags
    print(f'Interpolate from {args.from_ms} to {args.to_ms}')
    facet_number = f"{args.polygon.split("/")[-1].replace('.reg', '').replace('poly_', ''):02d}"
    interpolate(args.from_ms, args.to_ms, f"FACET_{facet_number}", True, './', True)
    phasecentre, freqavg, timeres, dirname = get_facet_info(args.polygon_info, args.to_ms, args.polygon)
    run_DP3(args.to_ms, phasecentre, freqavg, timeres, args.h5parm, dirname)

    # We can do this, since we have made a full copy
    if args.delete_input_ms:
        os.system(f"rm -rf {args.to_ms}")

if __name__ == '__main__':
    main()