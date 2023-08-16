from past.utils import old_div
import numpy as np
from astropy.wcs import WCS
from astropy.io import fits
import matplotlib.pyplot as plt
from matplotlib.colors import SymLogNorm, PowerNorm
import os
import pyregion
from astropy.visualization.wcsaxes import WCSAxes
import astropy.units as u
from astropy.cosmology import FlatLambdaCDM
from glob import glob
import tables
from astropy.wcs import utils
from astropy.coordinates import SkyCoord
import pandas as pd
import re

class Imaging:

    def __init__(self, fits_file: str = None, resolution: float = None):
        self.fitsfile = fits_file
        self.hdu = fits.open(fits_file)
        self.image_data = self.hdu[0].data
        while len(self.image_data.shape) != 2:
            self.image_data = self.image_data[0]
        self.wcs = WCS(self.hdu[0].header, naxis=2)
        self.header = self.wcs.to_header()
        self.rms = self.noise
        self.rms_full = self.rms.copy()
        self.cosmo = FlatLambdaCDM(H0=70 * u.km / u.s / u.Mpc, Tcmb0=2.725 * u.K, Om0=0.3)
        self.resolution = resolution
        self.beamarea_copy = self.beamarea

    @property
    def noise(self):
        """
        from Cyril Tasse/kMS
        """
        maskSup = 1e-7
        m = self.image_data[np.abs(self.image_data)>maskSup]
        rmsold = np.std(m)
        diff = 1e-1
        cut = 3.
        med = np.median(m)
        for _ in range(10):
            ind = np.where(np.abs(m - med) < rmsold*cut)[0]
            rms = np.std(m[ind])
            if np.abs(old_div((rms-rmsold), rmsold)) < diff: break
            rmsold = rms
        print(f'Noise : {str(round(rms * 1000, 4))} {u.mJy/u.beam}')
        self.rms = rms
        return rms

    @property
    def beamarea(self):
        try:
            # Given a fitsfile this calculates the beamarea in pixels

            if 'median' in self.fitsfile:
                hdu = fits.open(self.fitsfile.replace('median.fits', 'all.fits'))
                bmaj = hdu[0].header['BMAJ']
                bmin = hdu[0].header['BMIN']

                beammaj = bmaj / (2.0 * (2 * np.log(2)) ** 0.5)  # Convert to sigma
                beammin = bmin / (2.0 * (2 * np.log(2)) ** 0.5)  # Convert to sigma
                pixarea = abs(hdu[0].header['CDELT1']/2 * hdu[0].header['CDELT2']/2)

                beamarea = 2 * np.pi * 1.0 * beammaj * beammin  # Note that the volume of a two dimensional gaus$
                beamarea_pix = beamarea / pixarea

                return beamarea_pix

            bmaj = self.hdu[0].header['BMAJ']
            bmin = self.hdu[0].header['BMIN']

            beammaj = bmaj / (2.0 * (2 * np.log(2)) ** 0.5)  # Convert to sigma
            beammin = bmin / (2.0 * (2 * np.log(2)) ** 0.5)  # Convert to sigma
            pixarea = abs(self.hdu[0].header['CDELT1'] * self.hdu[0].header['CDELT2'])

            beamarea = 2 * np.pi * 1.0 * beammaj * beammin  # Note that the volume of a two dimensional gaus$
            beamarea_pix = beamarea / pixarea

            return beamarea_pix
        except:
            return self.beamarea_copy

    @staticmethod
    def get_beamarea(hdu):

        bmaj = hdu[0].header['BMAJ']
        bmin = hdu[0].header['BMIN']

        beammaj = bmaj / (2.0 * (2 * np.log(2)) ** 0.5)  # Convert to sigma
        beammin = bmin / (2.0 * (2 * np.log(2)) ** 0.5)  # Convert to sigma
        pixarea = abs(hdu[0].header['CDELT1'] * hdu[0].header['CDELT2'])

        beamarea = 2 * np.pi * 1.0 * beammaj * beammin  # Note that the volume of a two dimensional gaus$
        beamarea_pix = beamarea / pixarea

        return beamarea_pix

    def make_image(self, image_data=None, cmap: str = 'CMRmap', vmin=None, vmax=None, show_regions=None, wcs=None,
                   h5=None, selfcalnames=None, save=None):
        plt.style.use('ggplot')
        """
        Image your data with this method.
        image_data -> insert your image_data or plot full image
        cmap -> choose your preferred cmap
        """

        if image_data is None:
            image_data = self.image_data
        if vmin is None:
            vmin = self.rms
        else:
            vmin = vmin
        if vmax is None:
            vmax = self.rms*25

        if wcs is None:
            wcs = self.wcs


        fig = plt.figure(figsize=(7, 10), dpi=200)
        plt.subplot(projection=wcs)
        WCSAxes(fig, [0.1, 0.1, 0.8, 0.8], wcs=wcs)

        if show_regions is not None:

            r = pyregion.open(show_regions).as_imagecoord(header=self.hdu[0].header)
            patch_list, artist_list = r.get_mpl_patches_texts()

            for patch in patch_list:
                plt.gcf().gca().add_patch(patch)


        im = plt.imshow(image_data, origin='lower', cmap=cmap)

        if cmap=='Blues':
            im.set_norm(SymLogNorm(linthresh = vmin * 2, vmin=vmin, vmax = vmin * 15))
        else:
            im.set_norm(PowerNorm(vmin=0, vmax=vmax, gamma=1 / 2))

        if selfcalnames:
            if not os.path.exists('selfcal_pointings.csv'):
                make_selfcal_csv()
            for name, pointing in pd.read_csv('selfcal_pointings.csv').set_index('name').iterrows():
                print(name)
                c = SkyCoord(pointing['phase_center_ra'] * u.rad, pointing['phase_center_dec'] * u.rad)
                cpix = utils.skycoord_to_pixel(c, self.wcs)
                plt.scatter(float(cpix[0]), float(cpix[1]), s=80, marker='x', color='red', alpha=0.5)
                plt.annotate(name, (float(cpix[0]), float(cpix[1])), color='green', alpha=0.8)


        elif h5 is not None:
            H = tables.open_file(h5)
            dirs = H.root.sol000.source[:]["dir"]
            for d in dirs:
                c = SkyCoord(d[0] * u.rad, d[1] * u.rad)
                cpix = utils.skycoord_to_pixel(c, self.wcs)
                plt.scatter(float(cpix[0]), float(cpix[1]), s=80, marker='x', color='red', alpha=0.65)

        plt.xlabel('Right Ascension (J2000)', size=14)
        plt.ylabel('Declination (J2000)', size=14)
        plt.tick_params(axis='both', which='major', labelsize=12)

        plt.grid(False)
        plt.grid('off')

        if save is not None:
            plt.savefig(save, dpi=250, bbox_inches='tight')
        else:
            plt.show()

        return self

def make_selfcal_csv(path_to_folder='.', ms=False, h5=False):
    if not ms and not h5:
        print('ms or h5 has to be True')
    import casacore.tables as ct
    import csv
    header = ['name', 'phase_center_ra', 'phase_center_dec']
    with open('selfcal_pointings.csv', 'w', encoding='UTF8') as f:
        writer = csv.writer(f)
        writer.writerow(header)
        if ms:
            selfcals = [p for p in glob(path_to_folder+'/P*') if len(p.split('/')[-1]) == 6]
            for selfcal in selfcals:
                name=selfcal.split('/')[-1]
                t = ct.table(glob(selfcal+'/*.ms')[0]+'::FIELD')
                phasedir = np.ndarray.flatten(t.getcol("PHASE_DIR"))
                writer.writerow([name, phasedir[0], phasedir[1]])
                t.close()
        elif h5:
            selfcals = glob(path_to_folder+'/*.h5')
            for selfcal in selfcals:
                name = re.search('P[0-9]{5}', selfcal)[0]
                H = tables.open_file(selfcal)
                phasedir = np.ndarray.flatten(H.root.sol000.source[:]['dir'])
                writer.writerow([name, phasedir[0], phasedir[1]])
                H.close()


if __name__ == "__main__":

    import argparse

    parser = argparse.ArgumentParser(description='')
    parser.add_argument('--fits', type=str, help='path to fits', required=True)
    parser.add_argument('--h5', type=str, help='path to h5')
    parser.add_argument('--region', type=str, help='path to region')
    parser.add_argument('--solution_folder', type=str, help='path to selfcal solution folder to extract directions from')
    parser.add_argument('--resolution', type=float, help='resolution', default=1.2)
    parser.add_argument('--saveimage', action='store_true', help='save image')
    parser.add_argument('--selfcalnames', action='store_true', help='give selfcal names')
    parser.add_argument('--widefield', action='store_true', help='make widefield image')
    args = parser.parse_args()

    if args.saveimage:
        save='output.png'
    else:
        save=None

    im = Imaging(fits_file=args.fits,
                 resolution=args.resolution)

    if args.solution_folder is not None:
        make_selfcal_csv(args.solution_folder, h5=True)

    if args.widefield:
        im.make_image(show_regions=args.region,
                      h5=args.h5,
                      selfcalnames=args.selfcalnames,
                      save=save)
