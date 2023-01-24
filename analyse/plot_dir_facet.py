from past.utils import old_div
import numpy as np
from astropy.wcs import WCS
from astropy.io import fits
from astropy.nddata import Cutout2D
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D
from matplotlib.colors import SymLogNorm, LogNorm, PowerNorm
from reproject import reproject_interp
import string
import sys
from astropy.modeling.models import Gaussian2D
from astropy.convolution import convolve, Gaussian2DKernel
from matplotlib.ticker import LogLocator, LogFormatterSciNotation as LogFormatter
import os
from scipy.ndimage import gaussian_filter, filters
import pyregion
from pyregion.mpl_helper import properties_func_default
from astropy.visualization.wcsaxes import WCSAxes
from matplotlib.patches import ConnectionPatch
import astropy.units as u
from astropy.cosmology import FlatLambdaCDM
import warnings
import scipy.ndimage as sn
from scipy.stats.stats import pearsonr, spearmanr, linregress
from scipy.optimize import curve_fit
from scipy import stats
from shapely.geometry import Polygon, Point
from shapely.ops import cascaded_union
from matplotlib.path import Path
from shapely.ops import cascaded_union
import requests
from astropy.visualization import make_lupton_rgb
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
                   subim=None, h5=None, selfcalnames=False, save=None):
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

        if selfcalnames is not None:
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
                plt.scatter(float(cpix[0]), float(cpix[1]), s=80, marker='x', color='red')

        plt.xlabel('Right Ascension (J2000)', size=14)
        plt.ylabel('Declination (J2000)', size=14)
        plt.tick_params(axis='both', which='major', labelsize=12)

        plt.grid(False)

        if save is not None:
            plt.savefig(save, dpi=250, bbox_inches='tight')
        else:
            plt.show()

        return self

    def make_subimages(self, regionfile, cmap='CMRmap', save=None, beamsize=None, convolve=None):

        r = pyregion.open(regionfile).as_imagecoord(header=self.hdu[0].header)

        fig = plt.figure(figsize=(9, 15))
        fig.subplots_adjust(hspace=0.2, wspace=0.4)

        rows, cols = len(r)//2, 2

        for k, shape in enumerate(r):

            if k==0:
                k=1
            elif k==1:
                k=3
            elif k==2:
                k=4
            elif k==3:
                k=5
            elif k==4:
                k=0
            elif k==5:
                k=2

            s = np.array(shape.coord_list)

            crd = self.wcs.all_pix2world(s[0], s[1], 0)


            out = Cutout2D(
                data=self.image_data,
                position=(s[0], s[1]),
                size=(s[3], s[2]),
                wcs=self.wcs,
                mode='partial'
            )
            norm = SymLogNorm(linthresh=self.rms * 5, vmin=self.rms, vmax=self.rms*30)

            if convolve:
                image_data = self.convolve_image(out.data, convolve)
            else:
                image_data = out.data

            plt.subplot(rows, cols, k+1, projection=out.wcs)
            im = plt.imshow(image_data, origin='lower', cmap=cmap, norm=norm)
            if k%2==0 and self.resolution==6:
                plt.ylabel('Declination (J2000)', size=14)
            else:
                plt.ylabel(' ')

            if k>=4:
                plt.xlabel('Right Ascension (J2000)', size=14)
            else:
                plt.xlabel(' ')
            plt.tick_params(axis='both', which='major', labelsize=12)

            if type(self.resolution) == int and beamsize:
                beampix = self.resolution / (self.header['CDELT2'] * u.deg).to(u.arcsec).value/2
                x, y = beampix*1.5+out.data.shape[0]*0.03, beampix*1.5+out.data.shape[1]*0.03
                circle = plt.Circle((x, y), beampix, color='g',
                                    fill=True)
                rectanglefill = plt.Rectangle(
                    (x - beampix*3/2, y - beampix*3/2), beampix * 3,
                    beampix * 3, fill=True, color='white')
                rectangle = plt.Rectangle(
                    (x - beampix*3/2, y - beampix*3/2), beampix * 3,
                    beampix * 3, fill=False, color='black', linewidth=2)
                plt.gcf().gca().add_artist(rectangle)
                plt.gcf().gca().add_artist(rectanglefill)
                plt.gcf().gca().add_artist(circle)
            # plt.grid(False)

            def fixed_color(shape, saved_attrs):
                attr_list, attr_dict = saved_attrs
                attr_dict["color"] = "green"
                kwargs = properties_func_default(shape, (attr_list, attr_dict))

                return kwargs

            # r3 = pyregion.open('../regions/optical.reg').as_imagecoord(header=out.wcs.to_header())
            #
            # optical_sources = [np.array(r3[i].coord_list) for i in range(len(r3))]
            # optical_sources = [i for i in optical_sources if i[0]<s[3] and i[1]<s[2] and i[0]>0 and i[1]>0]
            # plt.scatter([i[0] for i in optical_sources], [i[1] for i in optical_sources], color='red', marker='x', s=80)

            r4 = pyregion.open('../regions/sourcelabels.reg').as_imagecoord(header=out.wcs.to_header())

            patch_list, artist_list = r4.get_mpl_patches_texts(fixed_color)

            # fig.add_axes(ax)
            for patch in patch_list:
                print(patch)
                plt.gcf().gca().add_patch(patch)
            for artist in artist_list:
                plt.gca().add_artist(artist)

        fig.subplots_adjust(top=0.8)
        # cbar_ax = fig.add_axes([0.22, 0.88, 0.6, 0.03]) # l, b, w, h
        # cbar = fig.colorbar(im, cax=cbar_ax, orientation='horizontal')
        # cbar.ax.set_xscale('log')
        # cbar.locator = LogLocator()
        # cbar.formatter = LogFormatter()
        # cbar.update_normal(im)
        # cbar.set_label('Surface brightness [Jy/beam]')

        plt.grid('off')
        plt.grid(False)
        if save:
            plt.savefig(save, dpi=250, bbox_inches="tight")
            plt.close()

        else:
            plt.show()

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
                print(name)
                writer.writerow([name, phasedir[0], phasedir[1]])
                t.close()
        elif h5:
            selfcals = glob(path_to_folder+'/best_solutions/*.h5')
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
    parser.add_argument('--selfcal_folder', type=str, help='path to selfcal folder')
    parser.add_argument('--resolution', type=float, help='resolution', default=1.2)
    parser.add_argument('--saveimage', action='store_true', help='save image')
    parser.add_argument('--selfcalnames', action='store_true', help='give selfcal names')
    parser.add_argument('--subregion', type=str, help='region file for cutout')
    parser.add_argument('--widefield', action='store_true', help='make widefield image')
    args = parser.parse_args()

    if args.saveimage:
        save='output.png'
    else:
        save=None

    im = Imaging(fits_file=args.fits,
                 resolution=args.resolution)

    if args.selfcal_folder is not None:
        make_selfcal_csv(args.selfcal_folder)

    if args.widefield:
        im.make_image(show_regions=args.region,
                      h5=args.h5,
                      selfcalnames=args.selfcalnames,
                      save=save)

    if args.subregion is not None:
        im.make_subimages(args.subregion, cmap='CMRmap', save=None)