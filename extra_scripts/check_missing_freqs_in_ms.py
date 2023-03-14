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
    if type(input) == str:
        input = glob(input)

    for n, ms in enumerate(input):
        t = ct.table(ms + '/::SPECTRAL_WINDOW')

        if n == 0:
            chans = t.getcol("CHAN_FREQ")
        else:
            chans = np.append(chans, t.getcol("CHAN_FREQ"))

        t.close()

    return np.sort(chans)


def check_channels(input, make_dummies):
    """
    :param input: list or string with measurement sets
    :return: True if no error, otherwise sys.exit
    """
    chans = get_channels(input)
    chan_diff = np.abs(np.diff(chans, n=2))
    # check gaps in freqs
    if np.sum(chan_diff) != 0:
        if not make_dummies:
            sys.exit("ERROR: there are channel gaps.")
        else:
            dummy_num = np.sum(chan_diff > 0) // 2
            file = open('mslist.txt', 'a')
            for n in range(dummy_num):
                print('dummy'+'_'+str(n)+'.ms added to mslist.txt')
                file.write('dummy'+'_'+str(n)+'.ms\n')
            file.close()
            sys.exit("WARNING: there is/are " + str(dummy_num) + " gaps.")

    return True


if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser(description='Validate MS')
    parser.add_argument('--ms', nargs='+', help='MS', required=True)
    parser.add_argument('--make_dummies', help='Make dummies for missing MS', action='store_true')

    args = parser.parse_args()

    if check_channels(input=args.ms, make_dummies=args.make_dummies):
        print('--- SUCCESS: freq gaps checked and no gaps found ---')
