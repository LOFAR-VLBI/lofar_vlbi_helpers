from astropy.coordinates import SkyCoord
from astropy.io import fits
from astropy import units as u
from astropy.visualization import simple_norm
from astropy.wcs import WCS
from matplotlib.pyplot import figure
import matplotlib.pyplot as plt
import numpy as np
import os
from glob import glob
from scipy.ndimage import gaussian_filter
import matplotlib.gridspec as gridspec
import matplotlib.ticker as ticker
from mpl_toolkits.axes_grid1.anchored_artists import AnchoredSizeBar
from matplotlib.colors import SymLogNorm, PowerNorm
import matplotlib.path as mpath
import matplotlib.patches as patches
from argparse import ArgumentParser
import pyregion
from astropy.nddata import Cutout2D
from astropy.wcs import WCS


def findrms(mIn,maskSup=1e-7):
    """
    find the rms of an array, from Cycil Tasse/kMS
    """
    m=mIn[np.abs(mIn)>maskSup]
    rmsold=np.std(m)
    diff=1e-1
    cut=3.
    bins=np.arange(np.min(m),np.max(m),(np.max(m)-np.min(m))/30.)
    med=np.median(m)
    for i in range(10):
        ind=np.where(np.abs(m-med)<rmsold*cut)[0]
        rms=np.std(m[ind])
        if np.abs((rms-rmsold)/rmsold)<diff: break
        rmsold=rms
    return rms


def parse_args():
    """
    Command line argument parser
    """

    parser = ArgumentParser(description='make wide-field by combining facets')
    parser.add_argument('--fits', type=str, nargs='+', help='fits images')
    # parser.add_argument('--region', type=str, nargs='+', help='regions corresponding to facets')
    return parser.parse_args()


def make_cutout(image_data, pos, size, wcs):
    """
    Make cutout

    :param image_data:
    :param pos:
    :param size:
    :param wcs:
    :return:
    """

    out = Cutout2D(
        data=image_data,
        position=pos,
        size=size,
        wcs=wcs,
        mode='partial'
    )

    return out.data, out.wcs

cmap = 'RdBu_r'

args = parse_args()
fitsfiles = args.fits

for i, fitsfile in enumerate(fitsfiles):

    print(fitsfile)

    if '000' in fitsfile.split('/')[-1]:
        n=0
        cycle='1'
    elif '002' in fitsfile.split('/')[-1]:
        n=1
        cycle='3'
    elif '009' in fitsfile.split('/')[-1]:
        n=2
        cycle='10'
    else:
        continue


    hdu = fits.open(fitsfile)
    imdata = hdu[0].data[0, 0, :, :]*1000
    h = hdu[0].header

    imdata, wcs = make_cutout(imdata, [imdata.shape[0]//2, imdata.shape[0]//2], [1000,1000], WCS(h, naxis=2))


    if i==0:
        fig, axes = plt.subplots(figsize=(16, 7.5), nrows=1, ncols=3)
        rms = findrms(imdata)
        vmin, vmax = -0.1, 30 * rms

    im = axes[n].imshow(imdata, origin='lower', cmap=cmap, norm=SymLogNorm(linthresh=abs(vmin), vmin=vmin, vmax=vmax))
    axes[n].set_yticks([])
    axes[n].set_xticks([])
    axes[n].set_title('Cycle '+cycle, fontsize=16)


    # axes[n].text(.02, .02, f'$\sigma=$'+str(round(findrms(imdata)*1000,1))+' $\\mu$Jy/beam', ha='left', va='bottom', transform=axes[n].transAxes, fontsize=15)

p0 = axes[0].get_position().get_points().flatten()
p2 = axes[2].get_position().get_points().flatten()

orientation='horizontal'
ax_cbar1 = fig.add_axes([p0[0], 0.1, p2[2] - p0[0], 0.03])
cb = plt.colorbar(im, cax=ax_cbar1, orientation=orientation)
cb.set_label('Surface brightness [mJy/beam]', size=16)
cb.ax.tick_params(labelsize=16)

cb.outline.set_visible(False)

# Extend colorbar
bot = -0.05
top = 1.05

# Upper bound
xy = np.array([[0, 1], [0, top], [1, top], [1, 1]])
if orientation == "horizontal":
    xy = xy[:, ::-1]

Path = mpath.Path

# Make Bezier curve
curve = [
    Path.MOVETO,
    Path.CURVE4,
    Path.CURVE4,
    Path.CURVE4,
]

color = cb.cmap(cb.norm(cb._values[-1]))
patch = patches.PathPatch(
    mpath.Path(xy, curve),
    facecolor=color,
    linewidth=0,
    antialiased=False,
    transform=cb.ax.transAxes,
    clip_on=False,
)
cb.ax.add_patch(patch)

# Lower bound
xy = np.array([[0, 0], [0, bot], [1, bot], [1, 0]])
if orientation == "horizontal":
    xy = xy[:, ::-1]

color = cb.cmap(cb.norm(cb._values[0]))
patch = patches.PathPatch(
    mpath.Path(xy, curve),
    facecolor=color,
    linewidth=0,
    antialiased=False,
    transform=cb.ax.transAxes,
    clip_on=False,
)
cb.ax.add_patch(patch)

# Outline
xy = np.array(
    [[0, 0], [0, bot], [1, bot], [1, 0], [1, 1], [1, top], [0, top], [0, 1], [0, 0]]
)
if orientation == "horizontal":
    xy = xy[:, ::-1]

Path = mpath.Path

curve = [
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
path = mpath.Path(xy, curve, closed=True)

patch = patches.PathPatch(
    path, facecolor="None", lw=1, transform=cb.ax.transAxes, clip_on=False
)
cb.ax.add_patch(patch)


fig.tight_layout(pad=1.0)
plt.savefig('output_selfcals.png', dpi=300)
plt.close()
