import numpy as np
from astropy.io import fits
from argparse import ArgumentParser

def beamarea(fitsfile):
    """
    Get beam size area
    :param fitsfile: fits file
    :return: beam size
    """

    hdu = fits.open(fitsfile)

    bmaj = hdu[0].header['BMAJ']
    bmin = hdu[0].header['BMIN']

    beammaj = bmaj / (2.0 * (2 * np.log(2)) ** 0.5)  # Convert to sigma
    beammin = bmin / (2.0 * (2 * np.log(2)) ** 0.5)  # Convert to sigma
    pixarea = abs(hdu[0].header['CDELT1'] * hdu[0].header['CDELT2'])

    beamarea = 2 * np.pi * 1.0 * beammaj * beammin  # Note that the volume of a two dimensional gaus$
    beamarea_pix = beamarea / pixarea

    return beamarea_pix

if __name__ == "__main__":
    parser = ArgumentParser(description='Get beam size in pixels')
    parser.add_argument('--fitsfile', type=str, help='fits file name')
    args = parser.parse_args()

    print(beamarea(args.fitsfile))
