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


def add_trailing_zeros(s: str, digitsize: int = 4) -> str:
    """
    Pad a string with leading zeros to a fixed width.

    Parameters
    ----------
    s : str
        Input string representing a number.
    digitsize : int, default=4
        Total width of the output string.

    Returns
    -------
    str
        Zero-padded string, e.g. "1" → "0001", "21" → "0021".
    """
    padded_string = "".join(repeat("0", digitsize)) + s
    return padded_string[-digitsize:]


def get_model_image(msin: str, model_images: list[str]) -> None:
    """
    Match model images to a MeasurementSet and prepare them for prediction.

    This function selects model images whose frequency coverage overlaps
    with the input Measurement Set, copies them to the current directory,
    and renames them into a consistent numbering scheme for WSClean.

    Parameters
    ----------
    msin : str
        Path to the input Measurement Set.
    model_images : list of str
        List of candidate model image FITS files.
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
        if not (fmin > fmax_ms or fmax < fmin_ms):
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

    Returns: Parsed arguments
    """

    parser = ArgumentParser(description="Get model images that match with MeasurementSet.")
    parser.add_argument('--ms', help='Input MeasurementSet', default=None)
    parser.add_argument('--model_images', help='Model image directory', default=None)
    return parser.parse_args()


def main():
    """
    Main function
    """

    args = parse_args()
    get_model_image(args.ms, glob(args.model_images+"/*.fits"))


if __name__ == '__main__':
    main()
