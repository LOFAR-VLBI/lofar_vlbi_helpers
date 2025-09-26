#!/usr/bin/env python3
# -*- coding: utf-8 -*-

__author__ = "Jurjen de Jong"

import os
from os.path import basename
import re
from argparse import ArgumentParser
import numpy as np
import tables
from glob import glob

from astropy.io import fits
from casacore.tables import table
from numba import njit, prange, set_num_threads
from joblib import Parallel, delayed


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


def predict(ms: str = None, model_images: list = None, h5parm: str = None, facet_region: str = None):
    """
    Prediction of facet and add to facet masks

    Args:
        ms: MeasurementSet
        model_images: Model images
        h5parm: h5 solutions
        facet_region: Polygon region corresponding to facet
    """

    f = fits.open(model_images[0])
    comparse = str(f[0].header['HISTORY']).replace('\n', '').split()
    prefix_name = re.sub(r"(-\d{4})?-model(-pb|-fpb)?\.fits$", "", basename(model_images[0]))
    model_column = basename(facet_region).replace(".reg","").upper()
    command = ['wsclean',
               '-predict',
               f'-model-column {model_column}',
               f'-name {prefix_name}',
               '-parallel-gridding 6',
               '-model-storage-manager stokes-i']
                #  -save-reordered


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


def get_shape(ms):
    with table(ms, ack=False) as t:
        freq, pol = t.getdesc()["DATA"]['shape']
        return (t.nrows(), freq, pol)


def create_memmap(facetnumber, shape, dtype):
    filename = f"FACET_{facetnumber}.dat"
    print(f"Creating {filename}")
    memmap_obj = np.memmap(filename, dtype=dtype, mode='w+', shape=(shape[0], shape[1]))
    memmap_obj[:] = 0  # Initialize the file with zeros
    return memmap_obj


def update_memmap(dat, polynumber, poly_data):
    # Extract facet number from the filename
    facet_id = basename(dat.filename).replace("FACET_", "").replace(".dat", "")
    if facet_id != polynumber:
        print(f"COMPUTE {dat.filename} + POLY_{polynumber}")
        # Get the column, convert to complex64, and add it in place
        add_in_place(dat, poly_data)


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


def copy_data(dat, to):
    os.system(f"rsync -avH --no-implied-dirs --copy-links {dat} {to}")


def parse_args():
    """
    Command line argument parser

    Returns
    -------
    Parsed arguments
    """

    parser = ArgumentParser("Predict facet masks for subtraction in MeasurementSet")
    parser.add_argument('--msin', help='Input MS', default=None)
    parser.add_argument('--model_images', nargs="+", help='Model images', default=None)
    parser.add_argument('--polygons', nargs="+", help='Polygon region files', default=None)
    parser.add_argument('--h5', help='Multidir-h5parm solutions', default=None)
    parser.add_argument('--ncpu', help='Number of CPUs for job', default=8, type=int)
    parser.add_argument('--tmp', type=str, help='Temporary directory to run I/O heavy jobs', default='.')

    return parser.parse_args()


def main():
    """
    Main function
    """

    args = parse_args()

    # Job requirements
    slurm_ncpu = int(os.getenv("SLURM_CPUS_PER_TASK", os.cpu_count() -1 ))
    ncpu = min(args.ncpu, slurm_ncpu)
    set_num_threads(ncpu) # For numba
    dtype = np.complex64

    if args.tmp != '.':
        rundir = args.tmp
        msin = basename(args.msin)
        model_images = [basename(m) for m in args.model_images]

        copy_data(args.msin, rundir)
        for model in args.model_images:
            copy_data(model, rundir)

        os.system(f"rm -rf {msin}") # Delete local MS to free up space

        outdir = os.getcwd()
        os.chdir(rundir)
    else:
        msin = args.msin
        model_images = args.model_images

    # Read the HDF5 file to get the number of facets
    with tables.open_file(args.h5) as T:
        dir_num = len(T.root.sol000.source[:]['dir'])

    # Get the shape for the memmap from msin (this function should be defined)
    shape = get_shape(msin)

    # Parallelize memmap creation
    memmaps = (Parallel(n_jobs=ncpu, backend='loky')(delayed(create_memmap)(facet, shape, dtype) for facet in range(dir_num)))

    # Predict
    for poly in args.polygons:
        polynumber = basename(poly).replace("poly_", "").replace(".reg", "")
        h5 = split_facet_h5(args.h5, f"Dir{int(float(polynumber)):02d}")
        predict(msin, model_images, h5, poly)
        # Adding polygon to memmap facet masks
        with (table(msin, ack=False) as t):
            poly_data = t.getcol(f"POLY_{polynumber}")[..., 0].astype(dtype)
            Parallel(n_jobs=ncpu, backend='loky')(delayed(update_memmap)(dat, polynumber, poly_data) for dat in memmaps)
        os.remove(h5)

    # Add final POLY_* to measurement set
    for dat in memmaps:
        datnum = basename(dat.filename).replace("FACET_","").replace(".dat","")
        column = f"POLY_{datnum}"

        with table(msin, ack=False, readonly=False) as t:
            print(f"Update POLY_{datnum} with FACET_{datnum}.dat")
            inp = add_axis(np.array(dat), 4)
            inp[..., 1] = 0
            inp[..., 2] = 0

            t.putcol(column, inp)

    if args.tmp != '.':
        # Copy output data back
        copy_data(msin, outdir)

    # Cleanup
    for dat in memmaps:
        os.remove(dat.filename)

    # Reorder files
    for tmpfile in glob(f"{msin}*.tmp"):
        os.remove(tmpfile)


if __name__ == '__main__':
    main()
