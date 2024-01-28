"""Sub-module for trimming FITS images."""

from astropy.io import fits
from astropy.nddata import Cutout2D
from astropy.wcs import WCS
import pyregion
from numpy import array
from typing import Union
import sys
import numpy as np
import astropy.units as u
import matplotlib.pyplot as plt
from astropy.coordinates import SkyCoord
from astropy.wcs.utils import skycoord_to_pixel
from matplotlib.colors import SymLogNorm, PowerNorm
from glob import glob


def get_rms(image_data):
    """
    from Cyril Tasse/kMS

    :param image_data: image data array
    :return: rms (noise measure)
    """
    from past.utils import old_div

    maskSup = 1e-7
    m = image_data[np.abs(image_data) > maskSup]
    rmsold = np.std(m)
    diff = 1e-1
    cut = 3.
    med = np.median(m)
    for _ in range(10):
        ind = np.where(np.abs(m - med) < rmsold * cut)[0]
        rms = np.std(m[ind])
        if np.abs(old_div((rms - rmsold), rmsold)) < diff: break
        rmsold = rms
    print(f'Noise : {str(round(rms * 1000, 4))} {u.microJy / u.beam}')
    return rms


def make_cutout_2D(image: str = None, pos: Union[list, tuple] = None,
                   size: Union[list, tuple] = None, outfile: str = None):
    """
    Make 2D cutout with astropy
    ---------------------------
    :param image: image name
    :param pos: central position
    :param size: image size
    :param outfile: output fits file
    """
    head = fits.getheader(image)
    data = fits.getdata(image).squeeze()
    if len(data.shape) > 2:
        raise ValueError(
            "Image data has dimensions other than RA and DEC, which is not yet supported."
        )
    wcs = WCS(head).celestial

    cutout = Cutout2D(data, pos, size, wcs=wcs)
    hdu = fits.PrimaryHDU(data=cutout.data, header=cutout.wcs.to_header())
    hdu.writeto(outfile)


def make_cutout_region(image: str = None, region: str = None, outfile: str = None):
    """
    Make 2D cutout with pyregion
    ---------------------------
    :param image: image name
    :param region: region file
    :param outfile: output fits file
    """

    hdu = fits.open(image)
    head = hdu[0].header
    data = hdu[0].data

    while data.ndim > 2:
        data = data[0]

    r = pyregion.open(region).as_imagecoord(header=head)
    mask = r.get_mask(hdu=hdu[0], shape=(head["NAXIS1"], head["NAXIS2"]))

    assert len(r) == 1, 'Multiple regions in 1 file given, only one allowed'

    shape = array(r[0].coord_list)

    # circle
    if len(shape) == 3:
        cutout = Cutout2D(data=data * mask,
                          position=(shape[0], shape[1]),
                          size=(shape[2], shape[2]),
                          wcs=WCS(head, naxis=2),
                          mode='partial')
    # square
    elif len(shape) > 3:
        print(shape)

        cutout = Cutout2D(data=data * mask,
                          position=(shape[0], shape[1]),
                          size=(shape[3], shape[2]),
                          wcs=WCS(head, naxis=2),
                          mode='partial')
    else:
        sys.exit("ERROR: Should not arrive here")

    hdu = fits.PrimaryHDU(data=cutout.data, header=cutout.wcs.to_header())
    hdu.writeto(outfile, overwrite=True)

def make_image(fitsfiles, cmap: str = 'RdBu_r', rmss=None, cbar=True, axes=True, symlognorm=False, txt=''):
    """
    Image your data with this method.
    fitsfiles -> list with fits file
    cmap -> choose your preferred cmap
    """

    for n, fitsfile in enumerate(sorted(fitsfiles)):

        hdu = fits.open(fitsfile)
        header = hdu[0].header


        if n==0:
            w = WCS(header, naxis=2)

            fig, axs = plt.subplots(2, 2,
                                    figsize=(18, 7),
                                    subplot_kw={'projection': w})

        imdat = hdu[0].data
        while imdat.ndim > 2:
            imdat = imdat[0]

        w = WCS(header, naxis=2)

        ax = plt.subplot(int(float(f'1{len(fitsfiles)}0')) + n+1, projection=w)

        imdat *= 1000

        if rmss is not None:
            rms = rmss[n]
        else:
            rms = get_rms(imdat)
        vmin = rms * 1.5
        vmax = rms * 25

        if n==0:
            vmin*=1.8
        if n==3:
            vmin/=10

        if 'example5_0.3.fits' == fitsfile:
            vmin*=1.7
        if 'example5_0.6.fits' == fitsfile:
            vmin*=1.6
        if 'example4_0.3.fits' == fitsfile:
            vmin*=1.4
        if 'example4_0.6.fits' == fitsfile:
            vmin*=1.3
        if 'example3_0.3.fits' == fitsfile:
            vmin*=1.4
        if 'example3_0.6.fits' == fitsfile:
            vmin*=1.2
        if 'example2_1.2.fits' == fitsfile or 'example3_1.2.fits'==fitsfile:
            vmin/=1.5




        # if n==3:
        #     im = ax.imshow(imdat, origin='lower', cmap=cmap, norm=SymLogNorm(linthresh=vmin, vmin=vmin/10, vmax=vmax))
        # else:

        if symlognorm:
            im = ax.imshow(imdat, origin='lower', cmap=cmap, norm=SymLogNorm(linthresh=vmin*2, vmin=vmin/4, vmax=vmax*1.5))
        else:
            im = ax.imshow(imdat, origin='lower', cmap=cmap, norm=PowerNorm(gamma=0.5, vmin=vmin, vmax=vmax))

        if axes:
            if n==0:
                # ax.set_xlabel('Right Ascension (J2000)', size=14)
                ax.set_ylabel('Declination (J2000)', size=14)

            else:
                ax.set_ylabel(' ', size=14)
                lon = ax.coords[1]
                lon.set_ticks_visible(False)
                lon.set_ticklabel_visible(False)
                # lat.set_ticks_visible(False)
                # lat.set_ticklabel_visible(False)
                lon.set_axislabel('')
                # lat.set_axislabel('')
        else:
            ax.set_ylabel(' ', size=14)
            ax.set_xlabel(' ', size=14)
            lon = ax.coords[1]
            lat = ax.coords[0]
            lon.set_ticks_visible(False)
            lon.set_ticklabel_visible(False)
            lat.set_ticks_visible(False)
            lat.set_ticklabel_visible(False)
            lon.set_axislabel('')
            lat.set_axislabel('')


        ax.set_xlabel('Right Ascension (J2000)', size=14)
        # axs[m, n % 2].set_tick_params(axis='both', which='major', labelsize=12)
        # if n!=0:
        #     ax.set_title(fitsfile.split('/')[-2].replace('_', ' '))
        if n==0:
            t = '0.3"'
        if n==1:
            t = '0.6"'
        if n==2:
            t = '1.2"'
        if n==3:
            t = '6"'
        if txt:
            t=txt

        bbox_props = dict(boxstyle='round', facecolor='white', edgecolor='black', alpha=0.15)

        if n!=3:
            ax.text(imdat.shape[0]//21, imdat.shape[1]*11/12, t, color='white', fontsize=18, ha='left', va='bottom', bbox=bbox_props)
        elif fitsfile=='example5_6.fits':
            ax.text(imdat.shape[0]//21+0.2, imdat.shape[1]*11/12-0.2, t, color='white', fontsize=18, ha='left', va='bottom', bbox=bbox_props)
        else:
            ax.text(imdat.shape[0]//21-0.35, imdat.shape[1]*11/12-0.2, t, color='white', fontsize=18, ha='left', va='bottom', bbox=bbox_props)



        if n==0:

            if 'example7' in fitsfiles[0]:
                l = 'A'
            elif 'example2' in fitsfiles[0]:
                l = 'B'
            elif 'example3' in fitsfiles[0]:
                l = 'C'
            elif 'example4' in fitsfiles[0]:
                l = 'D'
            else:
                l = 'X'
            ax.text(imdat.shape[0]//21-0.35, imdat.shape[1]*1/20-0.2, l, color='lightgreen', fontsize=24, ha='left', va='bottom')


        # ax.text(0,0, t, color='white', fontsize=12, ha='left', va='bottom', bbox=bbox_props)

        # p = 5/(header['CDELT2']*3600)
        # ax.plot([0, p], [imdat.shape[0]*7/8, imdat.shape[0]*7/8], color='white')
        if cbar:
            cb = fig.colorbar(im, ax=ax, orientation='horizontal', shrink=1, pad=0.1)
            cb.set_label('Surface brightness [mJy/beam]', size=12)
            cb.ax.tick_params(labelsize=12)

    fig.tight_layout(pad=1.0)
    plt.grid(False)
    plt.grid('off')
    plt.savefig(fitsfiles[0].split("_")[0] + '.png', dpi=250, bbox_inches='tight')


if __name__ == '__main__':
    # make_image(glob("example1_1.2.fits"), cmap='CMRmap', rmss=[35/1000], cbar=False, axes=False, symlognorm=True, txt='1.2"')
    # make_image(glob("example8_0.3.fits"), cmap='CMRmap', rmss=[10/1000], cbar=False, axes=False, symlognorm=True, txt='0.3"')

    # make_image(glob("example1_*.fits"), cmap='CMRmap', rmss=[7/1000, 20/1000, 50/1000, 400/1000], cbar=False, axes=False, symlognorm=True)
    make_image(glob("example2_*.fits"), rmss=[22/1000, 50/1000, 160/1000, 1100/1000], cmap='CMRmap')
    make_image(glob("example3_*.fits"), rmss=[25/1000, 58/1000, 300/1000, 1800/1000], cmap='CMRmap')
    make_image(glob("example4_*.fits"), rmss=[20/1000, 40/1000, 160/1000, 800/1000], cmap='CMRmap')
    make_image(glob("example5_*.fits"), rmss=[14/1000, 35/1000, 100/1000, 500/1000], cmap='CMRmap')
    make_image(glob("example6_*.fits"), rmss=[17/1000, 35/1000, 180/1000, 900/1000], cmap='CMRmap')
    make_image(glob("example7_*.fits"), rmss=[43/1000, 85/1000, 300/1000, 1500/1000], cmap='CMRmap')


