#!/usr/bin/env python3
# -*- coding: utf-8 -*-

__author__ = "Jurjen de Jong"

import os
import re
from argparse import ArgumentParser
import numpy as np
import tables
from glob import glob

from astropy.io import fits
from casacore.tables import table
from numba import njit, prange


@njit(parallel=True)
def add_in_place(acc, arr):
    """
    Adds the contents of array `arr` into `acc` element-wise in place.

    Parameters:
        acc (np.ndarray): The accumulator array.
        arr (np.ndarray): The array to add into acc.
    """
    flat_size = acc.size
    # Loop over all elements in parallel
    for i in prange(flat_size):
        acc.flat[i] += arr.flat[i]


def make_utf8(inp):
    """
    Convert input to utf8 instead of bytes

    :param inp: string input
    :return: input in utf-8 format
    """

    try:
        inp = inp.decode('utf8')
        return inp
    except (UnicodeDecodeError, AttributeError):
        return inp


def split_facet_h5(h5parm: str = None, dirname: str = None):
    """
    Split multi-facet h5parm

    :param h5parm: multi-facet h5parm
    :param dirname: direction name
    """

    outputh5 = f'{h5parm}.{dirname}.h5'
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
        # new_dirs['name'][0] = bytes('Dir' + str(0).zfill(2), 'utf-8')
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
    try:
        repack(outputh5)
    except:
        pass

    return outputh5


def repack(h5):
    """Repack function"""
    print(f'Repack {h5}')
    os.system(f'mv {h5} {h5}.tmp && h5repack {h5}.tmp {h5} && rm {h5}.tmp')


def predict(ms: str = None, model_images: list = None, h5parm: str = None, facet_region: str = None, save_model_data: bool = True):

    f = fits.open(model_images[0])
    comparse = str(f[0].header['HISTORY']).replace('\n', '').split()
    prefix_name = re.sub(r"(-\d{4})?-model(-pb|-fpb)?\.fits$", "", model_images[0].split("/")[-1])
    model_column = facet_region.split('/')[-1].replace(".reg","").upper()
    command = ['wsclean',
               '-predict',
               f'-model-column {model_column}',
               f'-name {prefix_name}',
               '-parallel-gridding 6']
    # '-model-storage-manager stokes-i',

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
        fts = fits.open(modim)[0]
        fdelt, fcent = fts.header['CDELT3'] / 2, fts.header['CRVAL3']

        freqboundary.append(str(int(fcent + fdelt)))
        # fts.close()

    if len(freqboundary) > 0:
        command += ['-channel-division-frequencies ' + ','.join(freqboundary)]

    if h5parm is not None:
        command += [f'-apply-facet-solutions {h5parm} amplitude000,phase000',
                    f'-facet-regions {facet_region}', '-apply-facet-beam',
                    f'-facet-beam-update {comparse[comparse.index("-facet-beam-update") + 1]}']

    command += [ms]

    # run
    print('\n'.join(command))
    predict_cmd = open("predict.cmd", "w")
    predict_cmd.write('\n'.join(command))
    predict_cmd.close()

    os.system(' '.join(command))

    if save_model_data:
        with table(ms, ack=False) as t:
            np.save(model_column+'.npy', t.getcol(model_column))


def parse_args():
    """
    Command line argument parser

    Returns
    -------
    Parsed arguments
    """

    parser = ArgumentParser()
    parser.add_argument('--msin', help='Input MS', default=None)
    parser.add_argument('--model_images', nargs="+", help='Model images', default=None)
    parser.add_argument('--polygons', nargs="+", help='Polygon region files', default=None)
    parser.add_argument('--h5', help='Multidir-h5parm solutions', default=None)

    return parser.parse_args()


def main():
    """
    Main function
    """

    args = parse_args()
    for poly in args.polygons:
        polynumber = int(float(poly.split("/")[-1].replace("poly_", "").replace(".reg", "")))
        h5 = split_facet_h5(args.h5, f"Dir{polynumber:02d}")
        predict(args.msin, args.model_images, h5, poly)

    model_data = glob('*.npy')
    for n, model in enumerate(model_data):
        print(f"Make facet mask for {model.replace('.npy', '')}")
        other_files = model_data[:n] + model_data[n+1:]

        # Load the first array to determine the shape and dtype.
        first_array = np.load(other_files[0])
        output = np.zeros(first_array.shape, dtype=first_array.dtype)

        # Loop over the remaining files, load each array, and add it in place.
        for filename in other_files:
            arr = np.load(filename)
            add_in_place(output, arr)

    os.system('rm *.npy')


if __name__ == '__main__':
    main()
