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
from astropy.visualization.wcsaxes import WCSAxes
import matplotlib.path as mpath
import matplotlib.patches as patches
from pyregion.mpl_helper import properties_func_default


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
    print(f'Noise : {str(round(rms * 1000, 4))} {u.mJy / u.beam}')
    return rms


def make_image(fts=None, save=None, cmap: str = 'CMRmap', cbar: bool = False, regions: list = [], resolution: str = None):
    """
    Image your data with this method.
    image_data -> insert your image_data or plot full image
    cmap -> choose your preferred cmap
    """

    hdu = fits.open(fts)
    image_data = hdu[0].data * 1000
    header = hdu[0].header
    RMS = get_rms(image_data)  # TODO: TEMPORARY
    vmin = RMS * 1.5
    vmax = RMS * 16

    wcs = WCS(hdu[0].header, naxis=2)

    fig = plt.figure(figsize=(7, 10), dpi=200)
    plt.subplot(projection=wcs)
    WCSAxes(fig, [0.1, 0.1, 0.8, 0.8], wcs=wcs)

    # image_data[image_data == np.inf] = np.nan
    # image_data[image_data == 0] = np.nan

    im = plt.imshow(image_data, origin='lower', cmap=cmap)

    # im.set_norm(PowerNorm(vmin=vmin, vmax=vmax, gamma=1 / 2))
    im.set_norm(SymLogNorm(vmin=vmin / 10, vmax=vmax, linthresh=vmin))

    plt.xlabel('Right Ascension (J2000)', size=12)
    plt.ylabel('Declination (J2000)', size=12)
    plt.tick_params(axis='both', which='major', labelsize=10)

    if cbar:

        orientation = 'horizontal'
        cb = fig.colorbar(im, orientation=orientation, pad=0.1, extend='neither')
        cb.set_label('Surface brightness [mJy/beam]', size=14)
        cb.ax.tick_params(labelsize=12)

        # Extend colorbar
        bot = -0.05
        top = 1.05

        # Upper bound
        xy_upper = np.array([[0, 1], [0, top], [1, top], [1, 1]])
        if orientation == "horizontal":
            xy_upper = xy_upper[:, ::-1]

        Path = mpath.Path
        curve = [Path.MOVETO, Path.CURVE4, Path.CURVE4, Path.CURVE4]

        color_upper = cb.cmap(cb.norm(cb._values[-1]))
        patch_upper = patches.PathPatch(
            mpath.Path(xy_upper, curve),
            facecolor=color_upper,
            linewidth=0,
            edgecolor='none',
            antialiased=False,
            transform=cb.ax.transAxes,
            clip_on=False,
        )
        cb.ax.add_patch(patch_upper)

        # Lower bound
        xy_lower = np.array([[0, 0], [0, bot], [1, bot], [1, 0]])
        if orientation == "horizontal":
            xy_lower = xy_lower[:, ::-1]

        color_lower = cb.cmap(cb.norm(cb._values[0]))
        patch_lower = patches.PathPatch(
            mpath.Path(xy_lower, curve),
            facecolor=color_lower,
            linewidth=0,
            edgecolor='none',
            antialiased=False,
            transform=cb.ax.transAxes,
            clip_on=False,
        )
        cb.ax.add_patch(patch_lower)

        # Outline
        xy_outline = np.array(
            [[0, 0], [0, bot], [1, bot], [1, 0], [1, 1], [1, top], [0, top], [0, 1], [0, 0]]
        )
        if orientation == "horizontal":
            xy_outline = xy_outline[:, ::-1]

        Path = mpath.Path
        curve_outline = [
            Path.MOVETO,
            Path.CURVE4,
            Path.CURVE4,
            Path.CURVE4,
            Path.LINETO,
            Path.CURVE4,
            Path.CURVE4,
            Path.CURVE4,
            Path.LINETO,
        ]
        path_outline = mpath.Path(xy_outline, curve_outline, closed=True)

        patch_outline = patches.PathPatch(
            path_outline, facecolor="None", lw=1, transform=cb.ax.transAxes, clip_on=False
        )
        cb.ax.add_patch(patch_outline)

    def fixed_color(shape, saved_attrs):
        attr_list, attr_dict = saved_attrs
        attr_dict["color"] = 'green'
        kwargs = properties_func_default(shape, (attr_list, attr_dict))

        return kwargs

    if len(regions)>0:
        for region in regions:
            r = pyregion.open(region).as_imagecoord(header=hdu[0].header)
            patch_list, artist_list = r.get_mpl_patches_texts(fixed_color)

            # fig.add_axes(ax)
            for patch in patch_list:
                plt.gcf().gca().add_patch(patch)
            # if colorbar:
            #     for artist in artist_list:
            #         if not subim:
            #             plt.gca().add_artist(artist)
    if resolution is not None:
        bbox_props = dict(boxstyle='round', facecolor='white', edgecolor='black', alpha=0.15)
        plt.text(image_data.shape[0] // 21, image_data.shape[1] * 11 / 12, resolution, color='white', fontsize=16, ha='left', va='bottom',
                bbox=bbox_props)

    plt.grid(False)
    plt.grid('off')

    if save is not None:
        plt.savefig(save, dpi=250, bbox_inches='tight')
    else:
        plt.show()


make_image("/project/lofarvwf/Share/jdejong/output/ELAIS/ALL_L/imaging/split_facets2/final_img_1.2/full-mosaic.fits",
           'widefield_1.2.png',
           regions=['/project/lofarvwf/Share/jdejong/output/ELAIS/ALL_L/imaging/split_facets2/paperplots/cutouts/facet_26_ex.reg',
                    '/project/lofarvwf/Share/jdejong/output/ELAIS/ALL_L/imaging/split_facets2/paperplots/cutouts/extra_region2.reg',
])
make_image("example1_1.2.fits", 'subimage_1.2.png', regions=['subreg.reg'])
make_image("sub_example1_0.3.fits", 'subsubimage_1.2.png', resolution='0.3"')

# make_image("/project/lofarvwf/Share/jdejong/output/ELAIS/ALL_L/imaging/split_facets2/final_img_0.6/full-mosaic.fits",
#            'widefield_0.6.png', regions=[])
