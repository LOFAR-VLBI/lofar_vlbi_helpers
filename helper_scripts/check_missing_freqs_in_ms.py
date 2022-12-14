"""
This script is to verify that freq bands are not missing in a measurement set.

Example:
    python check_missing_freqs_in_ms.py --ms myms*.ms
"""

import casacore.tables as ct
import numpy as np
import sys
from glob import glob

def get_channels(input):
    """
    :param input: list or string with measurement sets
    :return: sorted concatenated channels
    """
    if type(input)==str:
        input = glob(input)

    for n, ms in enumerate(input):
        t = ct.table(ms+'/::SPECTRAL_WINDOW')

        if n==0:
            chans = t.getcol("CHAN_FREQ")
        else:
            chans = np.append(chans, t.getcol("CHAN_FREQ"))

        t.close()

    return np.sort(chans)

def check_channels(input):
    """
    :param input: list or string with measurement sets
    :return: True if no error, otherwise sys.exit
    """
    chans = get_channels(input)
    chan_diff = np.abs(np.diff(chans, n=2))
    # check gaps in freqs
    if np.sum(chan_diff) != 0:
        sys.exit("ERROR: there are channel gaps.")

    return True

if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser(description='Validate MS')
    parser.add_argument('--ms', nargs='+', help='MS', required=True)

    args = parser.parse_args()

    if check_channels(args.ms):
        print('--- Gaps checked and no freq gaps ---')
