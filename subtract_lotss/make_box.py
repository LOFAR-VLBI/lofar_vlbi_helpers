#!/usr/bin/env python

"""Derived from Frits Sweijen: https://github.com/tikk3r/lofar-highres-widefield/blob/restructure/utils/make_box.py"""

import argparse
import ast
import math

import casacore.tables as ct


def main(msfile, box_size=2.5):
    ''' Generates a DS9 region file that is used to subtract a LoTSS skymodel from the data.

    Args:
        msfile (str): a measurement set to obtain the phase center from.
        box_size (float): size in degrees of the box outside which to subtract LoTSS. Defaults to 2.5

    Returns:
        None
    '''
    if (type(msfile) is list):
        ms = msfile[0]
    if (msfile.startswith('[')):
        ms = ast.literal_eval(msfile)[0]
    else:
        ms = msfile
    with ct.table(ms + '::FIELD') as field:
        phasedir = field.getcol('PHASE_DIR').squeeze()
        phasedir_deg = phasedir * 180. / math.pi
        # RA, DEC, Size, Rotation
        regionstr = 'fk5\nbox({ra:f},{dec:f},{size:f},{size:f},0.0) # color=green'.format(ra=phasedir_deg[0], dec=phasedir_deg[1], size=float(box_size))
    with open('boxfile.reg', 'w') as f:
        f.write(regionstr)
    return 0


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Make a box outside of which to subtract LoTSS.')
    parser.add_argument('msfile', nargs='+', help='A measurement set containing the relevant phase center.')
    parser.add_argument('box_size', type=float, default=2.5, help='Size of the subtract box in degrees.')

    args = parser.parse_args()
    if (type(args.msfile) is list) or (args.msfile.startswith('[')):
        msfile = list(args.msfile)[0]
    else:
        msfile = args.msfile

    main(msfile, box_size=args.box_size)