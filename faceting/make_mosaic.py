from __future__ import print_function
from reproject import reproject_interp,reproject_exact
from reproj_test import reproject_interp_chunk_2d
from auxcodes import die, get_rms, flatten
import sys
from astropy.io import fits
from astropy.wcs import WCS
import numpy as np
import pickle
import os.path
import glob

with open('mosaic-header.pickle') as f:
    header=pickle.load(f)
xsize=header['NAXIS1']
ysize=header['NAXIS2']

g=glob.glob('facet_*_smoothed_astrometry.fits')

for f in g:
    print(f)
    outfile=f.replace('smoothed','reprojected')
    if os.path.isfile(outfile): continue
    hdu=flatten(fits.open(f))
    r, footprint=reproject_interp_chunk_2d(hdu, header, hdu_in=0, blocks=(2000,2000),parallel=False)
    hdu = fits.PrimaryHDU(header=header,data=r)
    hdu.writeto(outfile,overwrite=True)
