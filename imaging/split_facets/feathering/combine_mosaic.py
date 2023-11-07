from __future__ import print_function
import sys
from astropy.io import fits
import numpy as np
import pickle
import os.path
from glob import glob
from astropy.io import fits
from astropy.wcs import WCS
import pickle
import sys
from argparse import ArgumentParser
import pyregion
from reproj_test import reproject_interp_chunk_2d
from auxcodes import flatten
from astropy.coordinates import SkyCoord
from shapely import geometry


def make_header(fitsfile):
    hdu = fits.open(fitsfile)
    himsize = fullpixsize // 2
    # construct template FITS header
    header = fits.Header()
    header['BITPIX'] = -32
    header['NAXIS'] = 2
    header['WCSAXES'] = 2
    header['NAXIS1'] = 2 * himsize
    header['NAXIS2'] = 2 * himsize
    header['CTYPE1'] = 'RA---SIN'
    header['CTYPE2'] = 'DEC--SIN'
    header['CUNIT1'] = 'deg'
    header['CUNIT2'] = 'deg'
    header['CRPIX1'] = himsize
    header['CRPIX2'] = himsize
    header['CRVAL1'] = hdu[0].header['CRVAL1']
    header['CRVAL2'] = hdu[0].header['CRVAL2']
    header['CDELT1'] = -hdu[0].header['CDELT2']
    header['CDELT2'] = hdu[0].header['CDELT2']
    header['LATPOLE'] = header['CRVAL2']
    header['BMAJ'] = hdu[0].header['BMAJ']
    header['BMIN'] = hdu[0].header['BMIN']
    header['BPA'] = hdu[0].header['BPA']
    header['TELESCOPE'] = 'LOFAR'
    header['OBSERVER'] = 'LoTSS'
    header['BUNIT'] = 'JY/BEAM'
    header['BSCALE'] = 1.0
    header['BZERO'] = 0
    header['BTYPE'] = 'Intensity'
    header['OBJECT'] = 'ELAIS-N1'
    return header


def get_polygon_center(regionfile):
    """
    get polygon center
    :param regionfile: region file
    :return:
    """
    regionfile = open(regionfile, 'r')
    lines = regionfile.readlines()
    regionfile.close()
    try:
        polygon = lines[4]
    except IndexError:
        polygon = lines[3]
    polyp = [float(p) for p in polygon.replace('polygon(', '').replace(')', '').replace('\n', '').split(',')]
    poly_geo = geometry.Polygon(tuple(zip(polyp[0::2], polyp[1::2])))
    return SkyCoord(f'{poly_geo.centroid.x}deg', f'{poly_geo.centroid.y}deg', frame='icrs')


def get_array_coordinates(pix_array, wcsheader):
    """
    Get coordinates from pixel

    :param pix_array: array with pixel coordinates
    :param wcsheader: wcs header
    :return:
    """
    pixarray = np.argwhere(pix_array)
    return wcsheader.pixel_to_world(pixarray[:, 0], pixarray[:, 1], 0, 0)[0]


def get_distance_weights(center, coord_array):
    """
    Get weights based on center polygon to coordinates in array

    :param center: center polygon
    :param coord_array: coordinates field
    :return:
    """
    return 1 / center.separation(coord_array).value


if __name__ == '__main__':
    parser = ArgumentParser(description='make wide-field')
    parser.add_argument('--resolution', help='resolution in arcsecond', required=True, type=float)
    parser.add_argument('--facets', type=str, nargs='+', help='facets to merge')
    args = parser.parse_args()

    resolution = args.resolution
    facets = args.facets

    if resolution == 0.3:
        taper = None
        pixelscale = 0.1  # arcsec
    elif resolution == 1.2:
        taper = '1.2asec'
        pixelscale = 0.4
    else:
        sys.exit('ERROR: only use resolution 0.3 or 1.2')

    fullpixsize = int(2.5 * 3600 / pixelscale)

    header_new = make_header(facets[0])
    print(header_new)

    xsize = header_new['NAXIS1']
    ysize = header_new['NAXIS2']

    isum = np.zeros([ysize, xsize], dtype="float32")
    weights = np.zeros_like(isum, dtype="float32")
    fullmask = np.zeros_like(isum, dtype=bool)

    for f in facets:
        print(f)

        hdu = fits.open(f)
        hduflatten = flatten(hdu)
        wcsheader = WCS(hdu[0].header)

        imagedata, _ = reproject_interp_chunk_2d(hduflatten, header_new, hdu_in=np.nan, parallel=False)

        reg = 'poly_' + f.split('-')[0].split('_')[-1] + '.reg'
        polycenter = get_polygon_center(reg)
        r = pyregion.open(reg).as_imagecoord(header=header_new)
        mask = r.get_mask(hdu=hdu[0], shape=(header_new["NAXIS1"], header_new["NAXIS2"])).astype(int)

        fullmask |= ~np.isnan(imagedata)
        coordinates = get_array_coordinates(imagedata, wcsheader)
        facetweight = get_distance_weights(polycenter, coordinates).reshape(imagedata.shape) * mask
        facetweight[np.isnan(facetweight)] = 0  # so we can add
        imagedata *= facetweight
        imagedata[np.isnan(imagedata)] = 0  # so we can add
        isum += imagedata
        weights += facetweight

    print('Finalizing...')

    isum /= weights
    isum[isum == np.inf] = np.nan
    isum[~fullmask] = np.nan

    hdu = fits.PrimaryHDU(header=header_new, data=isum)

    hdu.writeto('full-mosaic.fits', overwrite=True)
