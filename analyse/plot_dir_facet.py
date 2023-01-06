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
from radio_beam import Beams
import warnings
import scipy.ndimage as sn
from scipy.stats.stats import pearsonr, spearmanr, linregress
from scipy.optimize import curve_fit
from scipy import stats
from shapely.geometry import Polygon, Point
from shapely.ops import cascaded_union
from matplotlib.path import Path
from shapely.ops import cascaded_union
from get_panstar import getimages
import requests
from astropy.visualization import make_lupton_rgb
from glob import glob

class Imaging:

    def __init__(self, fits_file: str = None, resolution: int = None):
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

