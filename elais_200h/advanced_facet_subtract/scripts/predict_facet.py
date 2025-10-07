#!/usr/bin/env python3
# -*- coding: utf-8 -*-

__author__ = "Jurjen de Jong"

import os
from os.path import basename
import subprocess
import re
from argparse import ArgumentParser
import numpy as np
import tables
from glob import glob

from astropy.io import fits
from casacore.tables import table
from numba import njit, prange, set_num_threads
from joblib import Parallel, delayed


def make_utf8(inp: str | bytes) -> str:
    """
    Convert input from bytes to a UTF-8 string if necessary.

    Parameters
    ----------
    inp : str or bytes
        Input value, either already a string or a byte sequence.

    Returns
    -------
    str
        The input converted to a UTF-8 string (or returned unchanged if
        conversion is not applicable).
    """
    try:
        inp = inp.decode('utf8')
        return inp
    except (UnicodeDecodeError, AttributeError):
        return inp


def split_facet_h5(h5parm: str, dirname: str):
    """
    Split a multi-facet H5Parm file into per-direction solutions.

    Parameters
    ----------
    h5parm : str
        Path to the multi-facet H5Parm file.
    dirname : str
        Name of the direction to extract.
    """
    outputh5 = f'{basename(h5parm)}.{dirname}.h5'
    os.system(f'cp {h5parm} {outputh5}')

    with tables.open_file(outputh5, 'r+') as outh5:

        axes = make_utf8(outh5.root.sol000.phase000.val.attrs["AXES"])

        dir_axis = axes.split(',').index('dir')

        sources = outh5.root.sol000.source[:]
        dirs = [make_utf8(dir) for dir in sources['name']]
        dir_idx = dirs.index(dirname)

        def get_data(soltab, axis):
            return np.take(outh5.root.sol000._f_get_child(soltab)._f_get_child(axis)[:], indices=[dir_idx], axis=dir_axis)

        phase_w = get_data('phase000', 'weight')
        amplitude_w = get_data('amplitude000', 'weight')
        phase_v = get_data('phase000', 'val')
        amplitude_v = get_data('amplitude000', 'val')
        new_dirs = np.array([outh5.root.sol000.source[:][dir_idx]])
        dirs = np.array([outh5.root.sol000.phase000.dir[:][dir_idx]])

        outh5.remove_node("/sol000/phase000", "val", recursive=True)
        outh5.remove_node("/sol000/phase000", "weight", recursive=True)
        outh5.remove_node("/sol000/phase000", "dir", recursive=True)
        outh5.remove_node("/sol000/amplitude000", "val", recursive=True)
        outh5.remove_node("/sol000/amplitude000", "weight", recursive=True)
        outh5.remove_node("/sol000/amplitude000", "dir", recursive=True)
        outh5.remove_node("/sol000", "source", recursive=True)

        outh5.create_array('/sol000/phase000', 'val', phase_v)
        outh5.create_array('/sol000/phase000', 'weight', phase_w)
        outh5.create_array('/sol000/phase000', 'dir', dirs)
        outh5.create_array('/sol000/amplitude000', 'val', amplitude_v)
        outh5.create_array('/sol000/amplitude000', 'weight', amplitude_w)
        outh5.create_array('/sol000/amplitude000', 'dir', dirs)
        outh5.create_table('/sol000', 'source', new_dirs, title='Source names and directions')

        outh5.root.sol000.phase000.val.attrs['AXES'] = bytes(axes, 'utf-8')
        outh5.root.sol000.phase000.weight.attrs['AXES'] = bytes(axes, 'utf-8')
        outh5.root.sol000.amplitude000.val.attrs['AXES'] = bytes(axes, 'utf-8')
        outh5.root.sol000.amplitude000.weight.attrs['AXES'] = bytes(axes, 'utf-8')

    # Repack h5 to make size smaller
    repack(outputh5)

    return outputh5


def repack(h5):
    """
    Repack h5parm

    Parameters
    ----------
    h5 : str
        Path to h5parm
    """
    tmph5 = f"{h5}.tmp"
    print(f"Repacking {h5}...")
    os.rename(h5, tmph5)
    try:
        subprocess.run(["h5repack", tmph5, h5], check=True)
    finally:
        if os.path.exists(tmph5):
            os.rename(tmph5, h5)


def predict(ms: str, model_images: list[str], h5parm: str, facet_region: str):
    """
    Run WSClean prediction for a facet and update facet masks.

    Parameters
    ----------
    ms : str, optional
        Path to the Measurement Set.
    model_images : list of str, optional
        List of model image FITS files.
    h5parm : str, optional
        Path to H5Parm file containing calibration solutions.
    facet_region : str, optional
        DS9 region file (.reg) defining the facet polygon.
    """
    f = fits.open(model_images[0])
    comparse = str(f[0].header['HISTORY']).replace('\n', '').split()
    prefix_name = re.sub(r"(-\d{4})?-model(-pb|-fpb)?\.fits$", "", basename(model_images[0]))
    model_column = basename(facet_region).replace(".reg","").upper()
    command = ['wsclean',
               '-predict',
               f'-model-column {model_column}',
               f'-name {prefix_name}',
               '-parallel-gridding 6']

    for n, argument in enumerate(comparse):
        if argument in ['-gridder', '-padding',
                        '-idg-mode', '-beam-aterm-update', '-pol', '-scale']:
            if ' '.join(comparse[n:n + 2]) == '-gridder wgridder-apply-primary-beam':
                command.append('-gridder wgridder')
                command.append('-apply-primary-beam')
            else:
                command.append(' '.join(comparse[n:n + 2]))
        elif argument in ['-size']:
            command.append(' '.join(comparse[n:n + 3]))
        elif argument in ['-use-differential-lofar-beam', '-grid-with-beam',
                          '-use-idg', '-log-time', '-gap-channel-division',
                          '-apply-primary-beam']:
            if argument not in command:
                command.append(argument)

    if len(model_images) > 1:
        command += ['-channels-out ' + str(len(model_images))]

    freqboundary = []
    for modim in sorted(model_images)[:-1]:
        with fits.open(modim) as fts:
            fdelt, fcent = fts[0].header['CDELT3'] / 2, fts[0].header['CRVAL3']
            freqboundary.append(str(int(fcent + fdelt)))

    if len(freqboundary) > 0:
        command += ['-channel-division-frequencies ' + ','.join(freqboundary)]

    if h5parm is not None:
        command += [f'-apply-facet-solutions {h5parm} amplitude000,phase000',
                    f'-facet-regions {facet_region}', '-apply-facet-beam',
                    f'-facet-beam-update {comparse[comparse.index("-facet-beam-update") + 1]}']

    if len(glob(ms+"*.tmp"))>0:
        command += ['-reuse-reordered']
    else:
        command += ['-parallel-reordering 4']

    command += [ms]

    # Run predict
    print('\n'.join(command))
    predict_cmd = open("predict.cmd", "w")
    predict_cmd.write('\n'.join(command))
    predict_cmd.close()

    os.system(' '.join(command))


def copy_data(dat: str, to: str):
    """
    Copy a file or directory using rsync.

    Parameters
    ----------
    dat : str
        Path to the source file or directory.
    to : str
        Destination path.
    """
    os.system(f"rsync -avH --no-implied-dirs --copy-links {dat} {to}")


def parse_args():
    """
    Command line argument parser

    Returns
    -------
    Parsed arguments
    """
    parser = ArgumentParser("Predict facet masks for subtraction in MeasurementSet")
    parser.add_argument('--msin', help='Input MeasurementSet', default=None)
    parser.add_argument('--model_images', nargs="+", help='Model images', default=None)
    parser.add_argument('--polygon', help='Polygon region file', default=None)
    parser.add_argument('--h5', help='Multidir-h5parm solutions', default=None)
    parser.add_argument('--ncpu', help='Number of CPUs for job', default=8, type=int)
    parser.add_argument('--tmp', type=str, help='Temporary directory to run I/O heavy jobs', default='.')
    parser.add_argument('--cleanup_input', action='store_true', help='Delete input --msin to free up disk space. Only recommended if --msin is a copy of the original MeasurementSet.')

    return parser.parse_args()


def main():
    """
    Main function
    """

    args = parse_args()

    dtype = np.complex64

    # Copy data to --tmp if requested
    if args.tmp != '.':
        rundir = args.tmp
        msin = basename(args.msin)
        model_images = [basename(m) for m in args.model_images]

        copy_data(args.msin, rundir)
        for model in args.model_images:
            copy_data(model, rundir)

        if args.cleanup_input:
            os.system(f"rm -rf {msin}") # Delete input MS after copy to --tmp to free up space

        outdir = os.getcwd()
        os.chdir(rundir)
    else:
        msin = args.msin
        model_images = args.model_images
        outdir = '.'

    # Predict facet
    poly_number = basename(args.polygon).replace("poly_", "").replace(".reg", "")
    h5 = split_facet_h5(args.h5, f"Dir{int(float(poly_number)):02d}")
    predict(msin, model_images, h5, args.polygon)

    # Saving polygon data in Stokes I format
    with (table(msin, ack=False) as t):
        poly_data = t.getcol(f"POLY_{poly_number}")[..., 0].astype(dtype)
        np.save(f"{outdir}/POLY_{poly_number}.npy", poly_data)

    if args.cleanup_input:
        os.system(f"rm -rf {msin}") # Delete MS to free up space


if __name__ == '__main__':
    main()
