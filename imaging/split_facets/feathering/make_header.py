from astropy.io import fits
import pickle
import sys

resolution = 0.3

if resolution == 0.3:
    taper = None
    pixelscale = 0.07  # arcsec
elif resolution == 1.2:
    taper = '1.2asec'
    pixelscale = 0.4
else:
    sys.exit('ERROR: only use resolution 0.3 or 1.2')

fullpixsize = int(2.5 * 3600 / pixelscale)

def make_header(infile):
    hdu=fits.open(infile)
    himsize=fullpixsize//2
    # construct template FITS header
    header=fits.Header()
    header['BITPIX']=-32
    header['NAXIS']=2
    header['WCSAXES']=2
    header['NAXIS1']=2*himsize
    header['NAXIS2']=2*himsize
    header['CTYPE1']='RA---SIN'
    header['CTYPE2']='DEC--SIN'
    header['CUNIT1']='deg'
    header['CUNIT2']='deg'
    header['CRPIX1']=himsize
    header['CRPIX2']=himsize
    header['CRVAL1']=hdu[0].header['CRVAL1']
    header['CRVAL2']=hdu[0].header['CRVAL2']
    header['CDELT1']=-hdu[0].header['CDELT2']
    header['CDELT2']=hdu[0].header['CDELT2']
    header['LATPOLE']=header['CRVAL2']
    header['BMAJ']=hdu[0].header['BMAJ']
    header['BMIN']=hdu[0].header['BMIN']
    header['BPA']=hdu[0].header['BPA']
    header['TELESCOPE']='LOFAR'
    header['OBSERVER']='LoTSS'
    header['BUNIT']='JY/BEAM'
    header['BSCALE']=1.0
    header['BZERO']=0
    header['BTYPE']='Intensity'
    header['OBJECT']='ELAIS-N1'
    return header,himsize

header,_=make_header('facet_13_smoothed.fits') # Facet near image centre as template
with open('mosaic-header.pickle','w') as f:
    pickle.dump(header,f)


