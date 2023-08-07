"""
This script is to verify that freq bands are not missing in a measurement set.

Example:
    python check_missing_freqs_in_ms.py --ms myms*.ms
"""

__author__ = "Jurjen de Jong"

import casacore.tables as ct
import numpy as np
import sys
from glob import glob

def get_channels(input_ms):
    """
    :param input: list or string with measurement sets
    :return: sorted concatenated channels
    """

    # if string, make list and sort on name (so give clever names if you want to sort on freq)
    if type(input_ms) == str:
        input_ms = sorted(glob(input_ms))
    elif type(input_ms) == list:
        input_ms = sorted(input_ms)
    else:
        sys.exit("ERROR: wrong input type for "+str(input_ms)+" (only accept strings or lists).")

    if len(input_ms) == 0:
        sys.exit("ERROR: no MS given.")

    # collect all frequencies in 1 numpy array
    for n, ms in enumerate(input_ms):
        t = ct.table(ms + '/::SPECTRAL_WINDOW')

        if n == 0:
            chans = t.getcol("CHAN_FREQ")
        else:
            chans = np.append(chans, t.getcol("CHAN_FREQ"))

        t.close()

    return np.sort(chans), input_ms


def has_freq_gaps(input, make_dummies, output_name):
    """
    :param input: list or string with measurement sets
    :return: True if nog gaps, False if gaps
    """

    # get frequency channels
    chans, mslist = get_channels(input)
    # get differences between frequency steps
    chan_diff = np.abs(np.diff(chans, n=2))

    # file to write sorted list of MS
    file = open(output_name, 'w')

    # check gaps in freqs
    if np.sum(chan_diff) != 0:
        dummy_idx = set((np.ndarray.flatten(np.argwhere(chan_diff > 0))/len(chan_diff)*len(mslist)).round(0).astype(int))
        for n, idx in enumerate(dummy_idx):
            if make_dummies:
                print('dummy_'+str(n)+' between '+str(mslist[idx-1])+' and '+str(mslist[idx]))
                mslist.insert(idx, 'dummy_'+str(n))
            else:
                print('Gap between '+str(mslist[idx-1])+' and '+str(mslist[idx]))
        for ms in mslist:
            file.write(ms+'\n')
        file.close()
        return False
    else:
        for ms in mslist:
            file.write(ms + '\n')
        file.close()
        return True


if __name__ == '__main__':

    import argparse

    parser = argparse.ArgumentParser(description='Check for frequency gaps in MS')
    parser.add_argument('--ms', nargs='+', help='MS', required=True)
    parser.add_argument('--make_dummies', help='Make dummies for missing MS', action='store_true')
    parser.add_argument('--output_name', help='Output txt name', type=str, default='mslist.txt')

    args = parser.parse_args()

    if has_freq_gaps(input=args.ms, make_dummies=args.make_dummies, output_name=args.output_name):
        print('--- SUCCESS: no frequency gaps found ---')
