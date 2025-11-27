from astropy import units as u
from astropy.table import Table
from astropy.coordinates import match_coordinates_sky
from past.utils import old_div
import numpy as np
from astropy.wcs import WCS
from astropy.io import fits
import matplotlib.pyplot as plt
import pyregion
from astropy.visualization.wcsaxes import WCSAxes
import astropy.units as u
from glob import glob
import tables
from astropy.wcs import utils
from astropy.coordinates import SkyCoord
from scipy.interpolate import griddata
from scipy.ndimage import gaussian_filter
from matplotlib.path import Path


def find_matches(cat1, cat2, separation_asec):
    """
    Find crossmatches with two catalogues
    """

    catalog1 = Table.read(cat1, format='fits')
    catalog2 = Table.read(cat2, format='fits')

    coords1 = SkyCoord(ra=catalog1['RA'], dec=catalog1['DEC'], unit=(u.deg, u.deg))
    coords2 = SkyCoord(ra=catalog2['RA'], dec=catalog2['DEC'], unit=(u.deg, u.deg))

    idx_catalog2, separation, _ = match_coordinates_sky(coords1, coords2)

    max_sep_threshold = separation_asec * u.arcsec
    matched_sources_mask = separation < max_sep_threshold

    matched_sources_catalog1 = catalog1[matched_sources_mask]
    matched_sources_catalog2 = catalog2[idx_catalog2[matched_sources_mask]]

    return matched_sources_catalog1, matched_sources_catalog2

def scatter_with_scale(
    x, y, scales,
    xlabel=None, ylabel=None, title=None,
    cmap="cividis",
    fits_file=None,
    facets=None,
    smooth_sigma=10.0,      # Gaussian smoothing (in grid pixels)
    grid_res=400           # grid resolution
):

    # --- WCS setup ---
    hdu = fits.open(fits_file)
    wcs = WCS(hdu[0].header, naxis=2)

    fig = plt.figure(figsize=(8, 6))
    ax = fig.add_subplot(111, projection=wcs)

    # --- RA/Dec → pixel coordinates ---
    c = SkyCoord(x * u.deg, y * u.deg)
    xpix, ypix = utils.skycoord_to_pixel(c, wcs)
    xpix = np.asarray(xpix)
    ypix = np.asarray(ypix)

    # --- Interpolation grid (global, but we'll fill it facet by facet) ---
    nx = ny = grid_res
    gx = np.linspace(xpix.min(), xpix.max(), nx)
    gy = np.linspace(ypix.min(), ypix.max(), ny)
    GX, GY = np.meshgrid(gx, gy)

    # arrays to hold final per-facet smoothed map
    smear_smooth_all = np.full_like(GX, np.nan, dtype=float)

    # --- If no facets: fall back to global interpolation + smoothing -------
    if facets is None:
        smear_grid = griddata(
            points=(xpix, ypix),
            values=scales,
            xi=(GX, GY),
            method="linear"
        )

        fill_grid = griddata(
            points=(xpix, ypix),
            values=scales,
            xi=(GX, GY),
            method="nearest"
        )
        smear_grid = np.where(np.isfinite(smear_grid), smear_grid, fill_grid)

        smear_smooth_all = gaussian_filter(smear_grid, sigma=smooth_sigma)

    else:
        # --- Facets (DS9 regions in image coords) ---
        r = pyregion.open(facets).as_imagecoord(header=hdu[0].header)
        patch_list, artist_list = r.get_mpl_patches_texts()

        # draw patches
        for patch in patch_list:
            patch.set_edgecolor('black')
            patch.set_facecolor('none')
            ax.add_patch(patch)

        # precompute grid points as (x, y) list for Path.contains_points
        grid_points = np.column_stack((GX.ravel(), GY.ravel()))
        src_points  = np.column_stack((xpix, ypix))

        # loop over each region (facet)
        for shape in r:
            if shape.name.lower() != "polygon":
                # skip non-polygon regions
                continue

            coords = np.array(shape.coord_list)
            xs = coords[0::2]
            ys = coords[1::2]
            poly = Path(np.column_stack((xs, ys)))

            # mask of grid pixels inside this facet
            grid_mask_flat = poly.contains_points(grid_points)
            grid_mask = grid_mask_flat.reshape(GX.shape)

            if not np.any(grid_mask):
                continue

            # mask of source points inside this facet
            src_mask = poly.contains_points(src_points)
            if np.count_nonzero(src_mask) == 0:
                continue

            x_facet = xpix[src_mask]
            y_facet = ypix[src_mask]
            v_facet = np.asarray(scales)[src_mask]

            # choose interpolation method – need ≥3 points for linear
            method = "linear" if np.count_nonzero(src_mask) >= 3 else "nearest"

            # interpolate ONLY inside this facet
            Xi = GX[grid_mask]
            Yi = GY[grid_mask]
            facet_interp = griddata(
                points=(x_facet, y_facet),
                values=v_facet,
                xi=(Xi, Yi),
                method=method
            )

            # put facet interpolation into full-image array (NaN elsewhere)
            facet_grid = np.full_like(GX, np.nan, dtype=float)
            facet_grid[grid_mask] = facet_interp

            # ---------------------------------------------
            # Nearest-neighbour fill for NaNs *within facet*
            # ---------------------------------------------
            facet_fill = griddata(
                points=(x_facet, y_facet),
                values=v_facet,
                xi=(GX, GY),
                method="nearest"
            )

            # replace NaNs inside the facet with nearest neighbour
            facet_grid_filled = np.where(
                np.isnan(facet_grid) & grid_mask,
                facet_fill,
                facet_grid
            )

            # masked Gaussian smoothing: smooth(values*mask)/smooth(mask)
            mask_f = grid_mask.astype(float)

            num = gaussian_filter(
                np.nan_to_num(facet_grid_filled, nan=0.0) * mask_f,
                sigma=smooth_sigma
            )
            den = gaussian_filter(mask_f, sigma=smooth_sigma)

            facet_smooth = np.where(den > 0, num / den, np.nan)

            # write this facet into global smooth map
            smear_smooth_all = np.where(grid_mask, facet_smooth, smear_smooth_all)

    # --- Display smooth per-facet map ---
    im = ax.imshow(
        smear_smooth_all,
        origin="lower",
        extent=[gx.min(), gx.max(), gy.min(), gy.max()],
        cmap=cmap,
        aspect="equal"
    )

    # Optional: overplot original points
    # ax.scatter(xpix, ypix, c=scales, cmap=cmap, s=10,
    #            edgecolor="k", linewidth=0.2, alpha=0.7)

    # --- Colourbar & labels ---
    cbar = fig.colorbar(im, ax=ax)
    cbar.set_label("Smearing factor")

    if xlabel:
        ax.set_xlabel(xlabel)
    if ylabel:
        ax.set_ylabel(ylabel)
    if title:
        ax.set_title(title)

    plt.tight_layout()
    plt.show()

ra1 = []
dec1 = []
smearing1 = []
facets = glob('facet_*/facet_*avg1sec_source_catalog.fits')
for facet in facets:
    m1, m2 = find_matches('fullFoV_1sec/1.2asec-image-restored_source_catalog.fits',
                          facet,
                          1.0)
    mask = (m1['Peak_flux'] > 0.5) & (m1['Peak_flux'] < 1.1)
    m1 = m1[mask]
    m2 = m2[mask]

    ra1 += list(m1["RA"])
    dec1 += list(m1["DEC"])
    smearing1 += list(np.clip(m2['Peak_flux'] / m1['Peak_flux'], a_max=3.0, a_min=0.0))

ra2 = []
dec2 = []
smearing2 = []
facets = glob('facet_*/facet_*avg2sec_source_catalog.fits')
for facet in facets:
    m1, m2 = find_matches('fullFoV_1sec/1.2asec-image-restored_source_catalog.fits',
                          facet,
                          1.0)
    mask = (m1['Peak_flux'] > 0.5) & (m1['Peak_flux'] < 1.1)
    m1 = m1[mask]
    m2 = m2[mask]

    ra2 += list(m1["RA"])
    dec2 += list(m1["DEC"])
    smearing2 += list(np.clip(m2['Peak_flux'] / m1['Peak_flux'], a_max=3.0, a_min=0.0))

# m1, m2 = find_matches('fullFoV_1sec/1.2asec-image-restored_source_catalog.fits',
#                       'fullFoV_2sec/1.2asec-image-restored_source_catalog.fits',
#                       1.0)
# mask = (m1['Peak_flux'] > 0.5) & (m1['Peak_flux'] < 1.1)
# m1 = m1[mask]
# m2 = m2[mask]
#
# ra += list(m1["RA"])
# dec += list(m1["DEC"])
# smearing += list(np.clip(m2['Peak_flux'] / m1['Peak_flux'], a_max=3.0, a_min=0.0))

smearing = np.array(smearing1+smearing2)
ra = np.array(ra1+ra2)
dec = np.array(dec1+dec2)
# mask = smearing < 1.5
# smearing = smearing[mask]
# ra = ra[mask]
# dec = dec[mask]
ra %= 360

scatter_with_scale(ra, dec, smearing,
                   facets='/project/lofarvwf/Share/jdejong/output/ELAIS/ALL_200h/polygons/facets.reg',
                   fits_file='fullFoV_1sec/1.2asec-image.fits',
                   xlabel="Right Ascension (J2000)",
                   ylabel="Declination (J2000)")
