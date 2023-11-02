import pyregion
from astropy.io import fits
from numpy import nan
from argparse import ArgumentParser
from shapely import geometry
from astropy.coordinates import SkyCoord

if __name__ == '__main__':

    parser = ArgumentParser(description='Cut fits file based with region file')
    parser.add_argument('--fits_input', help='fits input file', required=True, type=str)
    parser.add_argument('--fits_output', help='fits output file', required=True, type=str)
    parser.add_argument('--region', help='region file', required=True, type=str)
    args = parser.parse_args()

    fitsfile = args.fits_input
    regionfile = args.region
    outputfits = args.fits_output

    hdu = fits.open(fitsfile)

    header = hdu[0].header

    r = pyregion.open(regionfile).as_imagecoord(header=header)
    mask = r.get_mask(hdu=hdu[0], shape=(header["NAXIS1"], header["NAXIS2"])).astype(int)
    imagedata = hdu[0].data.reshape(header["NAXIS1"], header["NAXIS2"])
    imagedata *= mask
    imagedata[imagedata == 0] = nan

    hdu = fits.PrimaryHDU(header=header, data=imagedata)
    hdu.writeto(outputfits, overwrite=True)
