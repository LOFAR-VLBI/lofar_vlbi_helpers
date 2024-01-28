import numpy as np
from shapely.geometry import Polygon, Point, MultiPolygon
import warnings
import astropy.units as u
import matplotlib.pyplot as plt
import numpy as np
from astropy import coordinates
from astropy.io import fits
from astropy.nddata import Cutout2D
from astropy.wcs import WCS
from matplotlib.colors import LogNorm, SymLogNorm, PowerNorm
import pyregion
import sys
from shapely.ops import cascaded_union
from matplotlib.path import Path
from shapely.affinity import affine_transform

warnings.filterwarnings("ignore")

warnings.filterwarnings("ignore")


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
    return rms

class MeasureSource:

    def __init__(self, fitsfile=None, region_mask=None, rms=None, rms_max_threshold=5, min_deg=None, maj_deg=None):

        self.hdu = fits.open(fitsfile)
        self.image_data = self.hdu[0].data
        while self.image_data.ndim>2:
            self.image_data = self.image_data[0]
        self.header = self.hdu[0].header
        self.wcs = WCS(self.header, naxis=2)

        self.poly_list = []
        self.region_mask = region_mask

        if region_mask:
            self.mask_region(self.image_data)

        if rms is None:
            self.rms = rms_max_threshold * get_rms(self.image_data)
        else:
            self.rms = rms_max_threshold * rms

        pix_size = abs((self.header['CDELT2'] * u.deg).to(u.arcsec).value)
        if min_deg and maj_deg:
            self.beam_pixels = (np.pi * (maj_deg * u.deg).to(u.arcsec) *
                                (min_deg * u.deg).to(u.arcsec)/pix_size**2).value
        else:
            self.beam_pixels = (np.pi * (self.header['BMAJ'] * u.deg).to(u.arcsec) *
                                (self.header['BMIN'] * u.deg).to(u.arcsec)/pix_size**2).value

        self.peak = self.peak_flux

    def _to_pixel(self, ra: float = None, dec: float = None):
        """
        To pixel position from RA and DEC in degrees
        ------------------------------------------------------------
        :param ra: Right ascension (degrees)
        :param dec: Declination (degrees)
        :return: Pixel of position
        """

        from astropy import wcs
        position = coordinates.SkyCoord(
            ra, dec, frame=wcs.utils.wcs_to_celestial_frame(self.wcs).name, unit=(u.degree, u.degree)
        )
        position = np.array(position.to_pixel(self.wcs))
        return position

    def make_cutout(self, pos: tuple = None, size: tuple = (1000, 1000), region: str = None):
        """
        Make cutout from your image.
        ------------------------------------------------------------
        :param pos: position in pixel size or degrees (RA, DEC)
        :param size: size of your image in pixels
        :param region: pyregion file (if given it ignores pos and size)
        """

        if region is not None:
            r = pyregion.open(region).as_imagecoord(header=self.hdu[0].header)
            mask = r.get_mask(hdu=self.hdu[0],
                              shape=(self.hdu[0].header["NAXIS1"], self.hdu[0].header["NAXIS2"])).astype(np.int16)
            if len(r) > 1:
                sys.exit('Multiple regions in 1 file given, only one allowed')
            else:
                shape = np.array(r[0].coord_list)
                # center = self.wcs.all_pix2world(shape[0], shape[1], 0)
                if len(shape) == 3:  # circle
                    cutout = Cutout2D(data=self.image_data * mask,
                                      position=(shape[0], shape[1]),
                                      size=(shape[2], shape[2]),
                                      wcs=self.wcs,
                                      mode='partial')
                elif len(shape) > 3:  # square
                    cutout = Cutout2D(data=self.image_data * mask,
                                      position=(shape[0], shape[1]),
                                      size=(shape[3], shape[2]),
                                      wcs=self.wcs,
                                      mode='partial')

        else:
            if type(pos[0]) != int and type(pos[1]) != int:
                pos = self._to_pixel(pos[0], pos[1])
            cutout = Cutout2D(data=self.image_data,
                              position=pos,
                              size=size,
                              wcs=self.wcs,
                              mode="partial")

        self.image_data = cutout.data
        self.header = cutout.wcs.to_header()

        return self

    def mask_region(self, region_mask):
        """
        :param image: image data
        :return: masked image data
        """

        r = pyregion.open(region_mask).as_imagecoord(header=self.header)
        mask = r.get_mask(hdu=self.hdu, shape=self.image_data.shape)
        self.image_data *= np.where(mask, 0, self.image_data)
        return self


    def _get_polylist(self, buff=0.2):
        """
        :param image: image data
        :return: list with polygons (source components)
        """

        # keep only surface brightness above noise level
        image = np.where((self.image_data > self.rms), self.image_data, 0)

        cs = plt.contour(image, [self.rms], colors='white', linewidths=1)
        cs_list = cs.collections[0].get_paths()

        self.poly_list = [Polygon(cs.vertices) for cs in cs_list if (Polygon(cs.vertices).is_valid == True
                                                                     and Polygon(cs.vertices).area > self.beam_pixels)]
        self.merged_geometry = cascaded_union(self.poly_list)
        if buff>0:
            self.merged_geometry = self.merged_geometry.buffer(buff)
        return self


    @property
    def _get_polygon_data(self):
        """
        :param image: image data
        :return: mask data outside polygon
        """

        mask = np.zeros(self.image_data.shape)
        for poly in self.poly_list:
            x, y = np.meshgrid(np.arange(len(self.image_data)), np.arange(len(self.image_data)))
            x, y = x.flatten(), y.flatten()
            points = np.vstack((x, y)).T
            grid = Path(poly.exterior.coords).contains_points(points)
            mask += grid.reshape(self.image_data.shape)
        mask = np.where(mask >= 1, np.ones(mask.shape), 0)
        image = self.image_data * mask
        return image

    @property
    def peak_flux(self):
        """
        Peak flux
        :return: maximum from polygon data
        """

        if len(self.poly_list)==0:
            self._get_polylist()
        return np.max(self._get_polygon_data)

    @staticmethod
    def flood_fill(matrix, start_coords, fill_value):
        """
        Flood fill algorithm.
        """
        stack = {(start_coords[0], start_coords[1])}
        while stack:
            x, y = stack.pop()
            if matrix[x, y] == fill_value:
                continue
            matrix[x, y] = fill_value
            stack |= set([(i, j) for i in range(x - 1, x + 2) for j in range(y - 1, y + 2)
                          if 0 <= i < matrix.shape[0] and 0 <= j < matrix.shape[1]])

    def make_plot(self):
        """
        Make plot with contour
        :return:
        """

        plt.close()
        imdat = self._get_polygon_data
        plt.contour(imdat, [self.rms], colors='white', linewidths=1)

        polygon = self.merged_geometry.boundary.convex_hull
        x, y = polygon.buffer(min(self.peak/(self.rms*2), np.sqrt(polygon.area))).exterior.xy

        plt.plot(x, y, label="Merged Polygon")
        plt.imshow(self.image_data,
                   norm=SymLogNorm(linthresh=self.rms, vmin=self.rms/10,
                                   vmax=self.rms*15),
                   cmap='magma')
        peak_pix = np.where(self.image_data==self.peak)
        plt.scatter(peak_pix[1], peak_pix[0], color='green', marker='*', zorder=2, s=100)
        plt.xticks([])
        plt.yticks([])
        plt.tight_layout()
        plt.show()
        plt.close()

# def main():
#     pass
#
# if __name__ == '__main__':
#     main()
