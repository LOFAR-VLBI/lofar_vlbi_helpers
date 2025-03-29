#!/usr/bin/env python3
# -*- coding: utf-8 -*-

__author__ = "Jurjen de Jong"

import tables
from astropy.wcs import WCS
from astropy.io import fits
from math import degrees
import numpy as np
import os
from argparse import ArgumentParser


def get_amp_scales(beam_file, h5):
    """
    Get beam scale

    Args:
        beam_file: fits file with beam scales
        h5: h5parm

    Returns: scale
    """

    with tables.open_file(h5) as H:
        dirs = H.root.sol000.source[:]['dir']

    with fits.open(beam_file) as hdul:
        header = hdul[0].header
        image = hdul[0].data.squeeze()
        wcs = WCS(header)

    scales = []
    for d in dirs:
        x_rad, y_rad = d
        deg_x = degrees(x_rad)
        deg_y = degrees(y_rad)
        pix_x, pix_y = wcs.world_to_pixel_values(deg_x, deg_y, 0, 0)[0:2]
        scalefactor = np.sqrt(image.squeeze()[int(pix_y), int(pix_x)])
        print(d, scalefactor)
        scales.append(scalefactor)

    return np.array(scales)


def scale_amps(beam_file, h5):
    """
    Scale amplitudes

    Args:
        beam_file: fits file with beam scales
        h5: h5parm
    """

    norm_h5 = f'norm_{h5.split("/")[-1]}'
    if not os.path.exists(norm_h5):
        os.system(f'cp {h5} {norm_h5}')

    with fits.open(beam_file) as bfits:
        freqdelt = bfits[0].header['CDELT3']/2
        freqcent = bfits[0].header['CRVAL3']
        minfreq, maxfreq = freqcent - freqdelt, freqcent + freqdelt

    amp_scales = get_amp_scales(beam_file, h5)

    with tables.open_file(norm_h5, 'r+') as H:
        freqs = H.root.sol000.amplitude000.freq[:]
        freqs_indices = np.argwhere((freqs>minfreq) & (freqs<maxfreq)).squeeze()
        H.root.sol000.amplitude000.val[:, list(freqs_indices), ...]/=amp_scales[np.newaxis, np.newaxis, np.newaxis, :, np.newaxis]


def parse_input():
    """
    Command line argument parser

    :return: arguments in correct format
    """

    parser = ArgumentParser(description='Normalize facet amplitude corrections to ensure primary beam correction + facet amplitude corrections are smooth without facet offsets')
    parser.add_argument('--beam_fits', type=str, help='Fits file with facet beam factors (without pb correction)', default='beamim-beam.fits')
    parser.add_argument('--h5', type=str, help='h5parm', default='merged.h5')

    return parser.parse_args()


def main():
    """
    Main function
    """

    args = parse_input()
    scale_amps(args.beam_fits, args.h5)


if __name__ == '__main__':
    main()
