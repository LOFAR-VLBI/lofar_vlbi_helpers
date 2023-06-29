from astropy.io import fits
from glob import glob

for n, f in enumerate(glob('L??????_2606/1.2image-MFS-image-pb.fits')):
    hdu = fits.open(f)
    if n == 0:
        imdat = hdu[0].data
    else:
        imdat += hdu[0].data
imdat /= n+1

hdunew = fits.PrimaryHDU(data=imdat, header=hdu[0].header)
hdunew.writeto('stacked.fits')