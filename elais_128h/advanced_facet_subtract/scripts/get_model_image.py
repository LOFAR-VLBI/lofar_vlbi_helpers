#!/usr/bin/env python3
# -*- coding: utf-8 -*-

__author__ = "Jurjen de Jong"

import os
import re
from argparse import ArgumentParser
from glob import glob
from itertools import repeat

from casacore.tables import table
from astropy.io import fits


def add_trailing_zeros(s, digitsize=4):
    """
     Repeat the zero character and add it to front

     :param s: string
     :param digitsize: number of digits (default 4)
     :return: trailing zeros + number --> example: 0001, 0021, ...
     """
    padded_string = "".join(repeat("0", digitsize)) + s
    return padded_string[-digitsize:]


def get_model_image(msin, model_images):
    """
    Get matching model images with MS
    """

    def rename_and_resort(pattern):
        """
        Rename and resort model images --> remove trailing zeros when only 1 model image, otherwise renumber model images
        """
        files = sorted(glob(pattern))
        if len(files) > 1:
            for n, modim in enumerate(files):
                new_name = re.sub(r'\d{4}', add_trailing_zeros(str(n), 4), modim)
                os.system(f'mv {modim} {new_name}')
        elif len(files) == 1:
            new_name = re.sub(r'\-\d{4}', '', files[0])
            os.system(f'mv {files[0]} {new_name}')

    # Get images with overlapping frequencies
    freqs = []
    with table(msin + "::SPECTRAL_WINDOW", ack=False) as t:
        freqs += list(t.getcol("CHAN_FREQ")[0])
    fmax_ms = max(freqs)
    fmin_ms = min(freqs)
    for modim in model_images:
        fts = fits.open(modim)[0]
        fdelt, fcent = fts.header['CDELT3'] / 2, fts.header['CRVAL3']
        fmin, fmax = fcent - fdelt, fcent + fdelt
        if fmin > fmax_ms or fmax < fmin_ms:
            print(f"Take {modim}")
            os.system(f"cp {modim} .")

    # Rename for WSClean predict
    model_patterns = ['*-????-model-fpb.fits', '*-????-model-pb.fits', '*-????-model.fits',
                      '*-model-fpb.fits', '*-model-pb.fits', '*-model.fits']
    for model_pattern in model_patterns[0:3]: rename_and_resort(model_pattern)

    return


def parse_args():
    """
    Command line argument parser

    Returns
    -------
    Parsed arguments
    """

    parser = ArgumentParser()
    parser.add_argument('--ms', help='Input MS', default=None)
    parser.add_argument('--model_images', help='Model images in directory', default=None)
    return parser.parse_args()


def main():
    """
    Main function
    """

    args = parse_args()
    get_model_image(args.ms, glob(args.model_images+"/*.fits"))


if __name__ == '__main__':
    main()
