#!/usr/bin/env python3
# -*- coding: utf-8 -*-

__author__ = "Jurjen de Jong"

import os
from os.path import basename
from argparse import ArgumentParser
import numpy as np
import tables

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


def update_memmap(dat: np.memmap, poly_number: int | str, poly_data: np.ndarray) -> None:
    """
    Update a memory-mapped facet file with polynomial data.

    Parameters
    ----------
    dat : np.memmap
        Memory-mapped array representing the facet data.
    poly_number : int or str
        Identifier for the polynomial data.
    poly_data : np.ndarray
        Array of data to be added in place.
    """
    facet_id = basename(dat.filename).replace("FACET_", "").replace(".dat", "")
    if facet_id != poly_number:
        print(f"COMPUTE {dat.filename} + POLY_{poly_number}")
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


def parse_args():
    """
    Command line argument parser

    Returns
    -------
    Parsed arguments
    """
    parser = ArgumentParser("Predict facet masks for subtraction in MeasurementSet")
    parser.add_argument('--msin', help='Input MS', default=None)
    parser.add_argument('--model_data_npy', nargs="+", help='Model data numpy files', default=None)
    parser.add_argument('--ncpu', help='Number of CPUs for job', default=8, type=int)
    parser.add_argument('--tmp', type=str, help='Temporary directory to write memmaps', default='.')

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

    # Write memmaps in --tmp
    if args.tmp != '.': os.chdir(args.tmp)

    # Get the shape for the memmap from msin
    shape = get_data_shape(args.msin)

    # Create memmaps
    memmaps = (Parallel(n_jobs=ncpu, backend='loky')(delayed(create_memmap)(facetnumber, shape, dtype) for facetnumber in range(len(args.model_data_npy))))

    # Predict facets
    for model_npy in args.model_data_npy:
        # Adding polygon to memmap facet masks
        poly_number = basename(model_npy).replace("POLY_", "").replace(".npy", "")
        poly_data = np.load(model_npy)
        Parallel(n_jobs=ncpu, backend='loky')(delayed(update_memmap)(dat, poly_number, poly_data) for dat in memmaps)

    # Add final POLY_* to measurement set
    for dat in memmaps:
        datnum = basename(dat.filename).replace("FACET_","").replace(".dat","")
        column = f"POLY_{datnum}"

        with table(args.msin, ack=False, readonly=False) as t:
            print(f"Update POLY_{datnum} with FACET_{datnum}.dat")
            inp = add_axis(np.array(dat), 4)
            inp[..., 1] = 0
            inp[..., 2] = 0

            colnames = t.colnames()

            if column not in colnames:
                desc = t.getcoldesc('DATA')
                print('Create ' + column)
                desc['name'] = column
                t.addcols(desc)

            t.putcol(column, inp)

    # Cleanup memmaps
    for dat in memmaps:
        os.remove(dat.filename)


if __name__ == '__main__':
    main()
