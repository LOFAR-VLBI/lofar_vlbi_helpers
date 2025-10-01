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
    """
    Repack h5parm

    Parameters
    ----------
    h5 : str
        Path to h5parm
    """
    print(f'Repack {h5}')
    os.system(f'mv {h5} {h5}.tmp && h5repack {h5}.tmp {h5} && rm {h5}.tmp')


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
               # '-save-reordered',
               # '-model-storage-manager stokes-i']

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


def get_data_shape(ms: str) -> tuple[int, int, int]:
    """
    Get the shape of the DATA column in a Measurement Set.

    Parameters
    ----------
    ms : str
        Path to the Measurement Set.

    Returns
    -------
    tuple of int
        A tuple (nrows, nfreq, npol) where:
        - nrows is the number of rows in the table,
        - nfreq is the number of frequency channels,
        - npol is the number of polarisations.
    """
    with table(ms, ack=False) as t:
        freq, pol = t.getdesc()["DATA"]['shape']
        return (t.nrows(), freq, pol)


def create_memmap(facetnumber: int | str, shape: tuple[int, int], dtype: np.dtype) -> np.memmap:
    """
    Create a zero-initialised memory-mapped array.

    Parameters
    ----------
    facetnumber : int or str
        Identifier for the facet, used in the filename.
    shape : tuple of int
        Dimensions of the array.
    dtype : data-type
        Data type of the array elements.

    Returns
    -------
    np.memmap
        The created memory-mapped array.
    """
    filename = f"FACET_{facetnumber}.dat"
    print(f"Creating {filename}")
    memmap_obj = np.memmap(filename, dtype=dtype, mode='w+', shape=(shape[0], shape[1]))
    memmap_obj[:] = 0  # Initialize the file with zeros
    return memmap_obj


def update_memmap(dat: np.memmap, polynumber: int | str, poly_data: np.ndarray) -> None:
    """
    Update a memory-mapped facet file with polynomial data.

    Parameters
    ----------
    dat : np.memmap
        Memory-mapped array representing the facet data.
    polynumber : int or str
        Identifier for the polynomial data.
    poly_data : np.ndarray
        Array of data to be added in place.
    """
    facet_id = basename(dat.filename).replace("FACET_", "").replace(".dat", "")
    if facet_id != polynumber:
        print(f"COMPUTE {dat.filename} + POLY_{polynumber}")
        # Get the column, convert to complex64, and add it in place
        add_in_place(dat, poly_data)


def add_axis(arr: np.ndarray, ax_size: int) -> np.ndarray:
    """
    Add a new axis to an array with a given size.

    Parameters
    ----------
    arr : np.ndarray
        Input array.
    ax_size : int
        Size of the new axis.

    Returns
    -------
    np.ndarray
        Array with an added axis of the specified size.
    """
    or_shape = arr.shape
    new_shape = list(or_shape) + [ax_size]
    return np.repeat(arr, ax_size).reshape(new_shape)


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
    slurm_ncpu = int(os.getenv("SLURM_CPUS_PER_TASK", os.cpu_count() - 1))
    ncpu = min(args.ncpu, slurm_ncpu)
    set_num_threads(ncpu) # For numba
    dtype = np.complex64

    # Copy data to --tmp if requested
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

    # Get the number of facets
    with tables.open_file(args.h5) as T:
        dir_num = len(T.root.sol000.source[:]['dir'])

    # Get the shape for the memmap from msin
    shape = get_data_shape(msin)

    # Create memmaps
    memmaps = (Parallel(n_jobs=ncpu, backend='loky')(delayed(create_memmap)(facet, shape, dtype) for facet in range(dir_num)))

    # Predict facets
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
        # Copy output data back if tmp used
        copy_data(msin, outdir)

    # Cleanup
    for dat in memmaps:
        os.remove(dat.filename)
    for tmpfile in glob(f"{msin}*.tmp"):
        os.remove(tmpfile)


if __name__ == '__main__':
    main()
