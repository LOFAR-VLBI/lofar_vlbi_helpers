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

    def __init__(self, fitsfile=None, region_mask=None, rms=None, rms_max_threshold=5, max_n_polygons=None):
        """
        Measure properties from a source
        ----------------------------------------
        :param fitsfile: Fits file
        :param region_mask: ds9 region mask
        :param rms: RMS noise (default: calculated by code)
        :param rms_max_threshold: RMS threshold above which flux is fitted for islands
        :param max_n_polygons: set a maximum number of polygons. For example 1 for compact sources
        """

        self.hdu = fits.open(fitsfile)
        self.image_data = self.hdu[0].data
        while self.image_data.ndim>2:
            self.image_data = self.image_data[0]
        self.header = self.hdu[0].header
        self.wcs = WCS(self.header, naxis=2)

        self.poly_list = []
        self.max_n_polygons = max_n_polygons
        self.region_mask = region_mask

        if region_mask:
            self.mask_region(self.image_data)

        if rms is None:
            self.rms_thresh = rms_max_threshold * get_rms(self.image_data)
        else:
            self.rms_thresh = rms_max_threshold * rms

        self.beam_pixels = self.beamarea
        self.peak = 0
        self.peak_flux_pos = [0, 0]
        self.cut_image_data = None
        self.cut_header = None

    @property
    def beamarea(self):
        """
        Calculate beam area in pixels
        -----------------------------
        :param bmaj: beam major axis
        :param bmin: beam minor axis
        :return:
        """

        bmaj = self.hdu[0].header['BMAJ']
        bmin = self.hdu[0].header['BMIN']

        beammaj = bmaj / (2.0 * (2 * np.log(2)) ** 0.5)  # Convert to sigma
        beammin = bmin / (2.0 * (2 * np.log(2)) ** 0.5)  # Convert to sigma
        pixarea = abs(self.hdu[0].header['CDELT1'] * self.hdu[0].header['CDELT2'])

        beamarea = 2 * np.pi * 1.0 * beammaj * beammin  # Note that the volume of a two dimensional gaus$
        beamarea_pix = beamarea / pixarea

        return beamarea_pix


    def _to_pixel(self, ra: float = None, dec: float = None):
        """
        To pixel position from RA and DEC in degrees
        --------------------------------------------
        :param ra: Right ascension (degrees)
        :param dec: Declination (degrees)
        :return: Pixel of position
        """

        from astropy import wcs
        position = coordinates.SkyCoord(
            ra, dec, frame=wcs.utils.wcs_to_celestial_frame(self.wcs).name, unit=(u.degree, u.degree)
        )
        position = np.array(position.to_pixel(self.wcs)).astype(int)
        
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
        Mask region with a ds9 region file
        -----------------------------------
        :param region_mask: ds9 region mask
        """

        r = pyregion.open(region_mask).as_imagecoord(header=self.header)
        mask = r.get_mask(hdu=self.hdu, shape=self.image_data.shape)
        self.image_data *= np.where(mask, 0, self.image_data)
        return self


    def _get_polylist(self, buff=0):
        """
        Get list with polygons
        --------------------------------------------------------
        :param buff: buffer to enlarge merged polygons in pixels
        :return: list with polygons (source components)
        """

        # keep only surface brightness above noise level
        image = np.where((self.image_data > self.rms_thresh), self.image_data, 0)

        cs = plt.contour(image, [self.rms_thresh], colors='white', linewidths=1)
        cs_list = cs.collections[0].get_paths()


        i = 1
        while len(self.poly_list)==0 and i<5:
            if len(self.poly_list)==0:
                self.poly_list = [Polygon(cs.vertices) for cs in cs_list if (Polygon(cs.vertices).is_valid == True
                                                                             and Polygon(cs.vertices).area > self.beam_pixels/i)]
            i+=1

        if i>1:
            self.max_n_polygons = 1

        # select max number of polygons based on distance from peak flux
        if self.max_n_polygons:
            if self.peak == 0:
                self.peak = self.peak_flux
            def calc_distance(p1, p2):
                """
                Calculate distance between two points
                :param p1: point 1
                :param p2: point 2
                :return: euclidean distance
                """
                return np.sqrt((p1[0] - p2[0]) ** 2 + (p1[1] - p2[1]) ** 2)

            self.poly_list.sort(key=lambda x: calc_distance(list(x.centroid.coords)[0], self.peak_flux_pos), reverse = False)
            self.poly_list = self.poly_list[0:self.max_n_polygons]

        self.merged_geometry = cascaded_union(self.poly_list)
        if buff>0:
            self.merged_geometry = self.merged_geometry.buffer(buff)
        return self


    @property
    def _get_polygon_data(self):
        """
        Get image data corresponding to polygons
        ----------------------------------------
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
    def largest_dist(self):
        """
        Calculate largest distance in convex hull
        -----------------------------------------
        :return:
        """

    @property
    def _get_convex_hull_data(self):
        """
        :param image: image data
        :return: mask data outside polygon
        """

        polygon = self.merged_geometry.boundary.convex_hull.exterior.coords
        x, y = np.meshgrid(np.arange(len(self.image_data)), np.arange(len(self.image_data)))
        x, y = x.flatten(), y.flatten()
        points = np.vstack((x, y)).T
        grid = Path(polygon).contains_points(points)
        mask = grid.reshape(self.image_data.shape)
        mask = np.where(mask >= 1, np.ones(mask.shape), 0)
        image = self.image_data * mask
        return image

    @property
    def peak_flux(self):
        """
        Peak flux in polygons
        :return: maximum from polygon data
        """

        if len(self.poly_list)==0:
            self._get_polylist()
        peakflux = np.max(self._get_polygon_data)
        self.peak_flux_pos = np.where(self.image_data==peakflux)
        return np.max(self._get_polygon_data)

    def make_plot(self, savefig: str = None):
        """
        Make plot with contour
        ---------------------
        """

        if self.peak == 0:
            self.peak = self.peak_flux

        plt.close()
        imdat = self._get_polygon_data
        plt.contour(imdat, [self.rms_thresh], colors='white', linewidths=1)

        polygon = self.merged_geometry.boundary.convex_hull
        x, y = polygon.exterior.xy

        plt.plot(x, y, label="Merged Polygon")
        plt.imshow(self.image_data,
                   norm=SymLogNorm(linthresh=self.rms_thresh, vmin=self.rms_thresh/10,
                                   vmax=self.rms_thresh*15),
                   cmap='magma')
        plt.scatter(self.peak_flux_pos[1], self.peak_flux_pos[0], color='green', marker='*', zorder=2, s=100)
        plt.xticks([])
        plt.yticks([])
        plt.tight_layout()
        if savefig is not None:
            plt.savefig(savefig, dpi=150)
        else:
            plt.show()
        plt.close()

        return self

# def main():
#     pass
#
# if __name__ == '__main__':
#     main()
