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
from mpl_toolkits.axes_grid1 import make_axes_locatable

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

fitsfiles = ['old_1.2_facet_22.fits', 'old_0.6_facet_22.fits', 'old_0.3_facet_22.fits', 'new_1.2_facet_22.fits', 'new_0.6_facet_22.fits', 'new_0.3_facet_22.fits']

fig, axes = plt.subplots(figsize=(16, 13), nrows=2, ncols=3)
# vmin, vmax = -0.003740546107292175, 0.22443276643753052
for n, fitsfile in enumerate(fitsfiles):

    try:
        hdu = fits.open(fitsfile)
        print(fitsfile)
    except:
        print(fitsfile + " does not exist")
        continue

    imdata = hdu[0].data[0, 0, :, :]*1000
    h = hdu[0].header

    # Extract beam size information from the header
    pixarea = abs(h['CDELT1'] / 2 * h['CDELT2'] / 2)
    beam_major = h['BMAJ'] / (2.0 * (2 * np.log(2)) ** 0.5)/np.sqrt(pixarea)  # Major axis of the beam
    beam_minor = h['BMIN'] / (2.0 * (2 * np.log(2)) ** 0.5)/np.sqrt(pixarea)  # Minor axis of the beam
    beam_pa = h['BPA']  # Position angle of the beam



    if '1.2' in fitsfile:
        imdata, wcs = make_cutout(imdata, [imdata.shape[0]//2, imdata.shape[0]//2], [int(1000*1.5/0.4),int(1000*1.5/0.4)], WCS(h, naxis=2))
    elif '0.6' in fitsfile:
        imdata, wcs = make_cutout(imdata, [imdata.shape[0]//2, imdata.shape[0]//2], [int(1000*1.5/0.2),int(1000*1.5/0.2)], WCS(h, naxis=2))
    elif '0.3' in fitsfile:
        imdata, wcs = make_cutout(imdata, [imdata.shape[0]//2, imdata.shape[0]//2], [int(1000*1.5/0.1),int(1000*1.5/0.1)], WCS(h, naxis=2))

    if n==0 or n==3:
        rms = 0.03851416
    if n==1 or n==4:
        rms = 0.021058151
    if n==2 or n==5:
        rms = 0.015080457
    # rms = findrms(imdata)

    vmin, vmax = -rms/10, 20 * rms

    if n<3:
        i, j = 0, n
    else:
        i, j = 1, n%3
    im = axes[i,j].imshow(imdata, origin='lower', cmap=cmap, norm=PowerNorm(gamma=1/2, vmin=vmin, vmax=vmax))
    axes[i,j].set_yticks([])
    axes[i,j].set_xticks([])
    if n<=2:
        axes[i,j].set_title(fitsfile.split("_")[1]+'" before', fontsize=16)
    else:
        axes[i,j].set_title(fitsfile.split("_")[1]+'" after', fontsize=16)

    # Draw an ellipse representing the beam
    ellipse_position = (imdata.shape[0]//16, imdata.shape[0]//16)  # Adjust as needed
    beam_ellipse = patches.Ellipse(
        ellipse_position,
        width=beam_major,
        height=beam_minor,
        angle=-beam_pa,
        fill=False,
        edgecolor='red',
        linestyle='dashed'
    )
    axes[i,j].add_patch(beam_ellipse)


    if i==1 and j in [0,1,2]:
        # Create rounded horizontal colorbars
        divider1 = make_axes_locatable(axes[i, j])
        cax1 = divider1.append_axes("bottom", size="5%", pad=0.1)
        cbar1 = plt.colorbar(im, cax=cax1, orientation='horizontal')
        if j==0:
            positive_ticks = [0., 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7]  # Add more ticks as needed
            cbar1.set_ticks(positive_ticks, size=14)
        if j==1:
            positive_ticks = [0., 0.1, 0.2, 0.3, 0.4]  # Add more ticks as needed
            cbar1.set_ticks(positive_ticks, size=14)
        if j==2:
            positive_ticks = [0., 0.1, 0.2, 0.3]  # Add more ticks as needed
            cbar1.set_ticks(positive_ticks, size=14)



# p0 = axes[1,0].get_position().get_points().flatten()
# p2 = axes[1,2].get_position().get_points().flatten()
#
# orientation='horizontal'
# ax_cbar1 = fig.add_axes([p0[0], 0.07, p2[2] - p0[0], 0.03])
# cb = plt.colorbar(im, cax=ax_cbar1, orientation=orientation)
# cb.set_label('Surface brightness [mJy/beam]', size=16)
# cb.ax.tick_params(labelsize=16)
#
# cb.outline.set_visible(False)
#
# # Extend colorbar
# bot = -0.05
# top = 1.05
#
# # Upper bound
# xy = np.array([[0, 1], [0, top], [1, top], [1, 1]])
# if orientation == "horizontal":
#     xy = xy[:, ::-1]
#
# Path = mpath.Path
#
# # Make Bezier curve
# curve = [
#     Path.MOVETO,
#     Path.CURVE4,
#     Path.CURVE4,
#     Path.CURVE4,
# ]
#
# color = cb.cmap(cb.norm(cb._values[-1]))
# patch = patches.PathPatch(
#     mpath.Path(xy, curve),
#     facecolor=color,
#     linewidth=0,
#     antialiased=False,
#     transform=cb.ax.transAxes,
#     clip_on=False,
# )
# cb.ax.add_patch(patch)
#
# # Lower bound
# xy = np.array([[0, 0], [0, bot], [1, bot], [1, 0]])
# if orientation == "horizontal":
#     xy = xy[:, ::-1]
#
# color = cb.cmap(cb.norm(cb._values[0]))
# patch = patches.PathPatch(
#     mpath.Path(xy, curve),
#     facecolor=color,
#     linewidth=0,
#     antialiased=False,
#     transform=cb.ax.transAxes,
#     clip_on=False,
# )
# cb.ax.add_patch(patch)
#
# # Outline
# xy = np.array(
#     [[0, 0], [0, bot], [1, bot], [1, 0], [1, 1], [1, top], [0, top], [0, 1], [0, 0]]
# )
# if orientation == "horizontal":
#     xy = xy[:, ::-1]
#
# Path = mpath.Path
#
# curve = [
#     Path.MOVETO,
#     Path.CURVE4,
#     Path.CURVE4,
#     Path.CURVE4,
#     Path.LINETO,
#     Path.CURVE4,
#     Path.CURVE4,
#     Path.CURVE4,
#     Path.LINETO,
# ]
# path = mpath.Path(xy, curve, closed=True)
#
# patch = patches.PathPatch(
#     path, facecolor="None", lw=1, transform=cb.ax.transAxes, clip_on=False
# )
# cb.ax.add_patch(patch)


fig.tight_layout(pad=1.0)
fig.subplots_adjust(wspace=0.02, hspace=0.02, bottom=0.1)
plt.savefig('output_selfcals.png', dpi=300)
plt.close()
