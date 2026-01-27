from scipy.special import erf
import numpy as np
import matplotlib.pyplot as plt

from astropy.io import fits
from astropy.wcs import WCS
from astropy.coordinates import SkyCoord
import astropy.units as u

import pyregion
from matplotlib.path import Path
import pandas as pd


def fluxration_smearing(central_freq_hz, bandwidth_hz, integration_time_s, resolution,
                                         distance_from_phase_center_deg):
    """
    Calculate the expected peak flux over integrated flux ratio due to smearing,
    as a function of distance from the pointing center.
    """

    theta = np.deg2rad(distance_from_phase_center_deg)
    theta_res = resolution * (np.pi / (180.0 * 3600.0))  # FWHM in rad

    # --- Bandwidth smearing (Bridle 18-24) ---
    gamma = 2.0 * np.sqrt(np.log(2.0))
    beta = (bandwidth_hz / central_freq_hz) * (theta / theta_res)

    # Avoid division by zero at beta=0
    bw_smearing = np.ones_like(beta, dtype=float)
    nonzero = beta != 0
    bw_smearing[nonzero] = (
        erf(gamma * beta[nonzero] / 2.0) * np.sqrt(np.pi) / (gamma * beta[nonzero])
    )

    # --- Time smearing (Bridle 18-43; small-angle approx) ---
    # Note: the 1.2288e-9 constant bakes in Earth rotation etc.
    x = integration_time_s * theta / theta_res
    time_smearing = 1.0 - 1.2288710615597145e-09 * x**2

    # clip to [0,1] to avoid negative nonsense when approximation breaks down
    bw_smearing = np.clip(bw_smearing, 0.0, 1.0)
    time_smearing = np.clip(time_smearing, 0.0, 1.0)

    total_smearing = bw_smearing * time_smearing
    return time_smearing, bw_smearing, total_smearing


def get_largest_divider(inp, integer):
    """
    Get largest divider

    :param inp: input number
    :param max: max divider

    :return: largest divider from inp bound by max
    """
    for r in range(integer+1)[::-1]:
        if inp % r == 0:
            return r


def plot_theoretical_smearing(
    fits_file,
    csv_file,
    facets,
    central_freq_hz,
    bandwidth_hz,
    integration_time_s,
    resolution_arcsec,
    grid_res=800,
    cmap="cividis"
):
    """
    Compute and plot the *theoretical* smearing map using fluxration_smearing,
    evaluated on a fine grid, but only inside the supplied facet polygons.

    Parameters
    ----------
    fits_file : str
        Image/FITS file with WCS (used for geometry + phase centre).
    facets : str
        DS9 region file with facet layout (polygons in fk5 or image coords).
    central_freq_hz : float
        Central observing frequency in Hz.
    bandwidth_hz : float
        Channel / bandwidth in Hz.
    integration_time_s : float
        Integration time per visibility in seconds.
    resolution_arcsec : float
        Synthesised beam FWHM in arcseconds (for the smearing formula).
    grid_res : int, optional
        Resolution of the smearing grid (grid_res x grid_res).
    cmap : str, optional
        Matplotlib colormap for the map.
    """

    df = pd.read_csv(csv_file)

    # --- WCS & image geometry ----------------------------------------------
    with fits.open(fits_file) as hdul:
        header = hdul[0].header

    wcs = WCS(header, naxis=2)

    # full image pixel size
    nx_img = header["NAXIS1"]
    ny_img = header["NAXIS2"]

    # fine regular grid in pixel space (0..nx_img-1, 0..ny_img-1)
    gx = np.linspace(0, nx_img - 1, grid_res)
    gy = np.linspace(0, ny_img - 1, grid_res)
    GX, GY = np.meshgrid(gx, gy)

    # empty grid for smearing (NaN outside facets)
    smear_total_grid = np.full_like(GX, np.nan, dtype=float)

    # phase centre from WCS
    ra0_deg, dec0_deg = wcs.wcs.crval
    phase_centre = SkyCoord(ra0_deg * u.deg, dec0_deg * u.deg)
    print(ra0_deg, dec0_deg)

    # precompute grid points for Path.contains_points
    grid_points = np.column_stack((GX.ravel(), GY.ravel()))

    # Keep patches for plotting outlines
    all_patches = []

    # ----- Loop over facets -----
    for _, row in df.iterrows():
        poly_file = '/project/lofarvwf/Share/jdejong/output/ELAIS/ALL_200h/polygons/'+row["polygon_file"]
        avg_factor = float(row["avg"])
        freqavg = avg_factor
        if freqavg==3:
            freqavg-=1

        # Region for this facet, in image coords
        reg = pyregion.open(poly_file).as_imagecoord(header=header)
        patch_list, _ = reg.get_mpl_patches_texts()
        all_patches.extend(patch_list)

        # assume a single polygon per file
        shape = reg[0]
        if shape.name.lower() != "polygon":
            continue

        coords = np.array(shape.coord_list)
        xs = coords[0::2]
        ys = coords[1::2]
        poly = Path(np.column_stack((xs, ys)))

        # mask of grid pixels inside this facet
        mask_flat = poly.contains_points(grid_points)
        mask = mask_flat.reshape(GX.shape)
        if not np.any(mask):
            continue

        # ---- parse poly_center, e.g. "[242.51157deg,55.87854deg]" ----
        center_str = row["poly_center"].strip("[]")
        ra_str, dec_str = center_str.split(",")
        ra_deg = float(ra_str.replace("deg", ""))
        dec_deg = float(dec_str.replace("deg", ""))
        facet_centre = SkyCoord(ra_deg * u.deg, dec_deg * u.deg)

        # pixel coords of grid points in this facet
        x_pix = GX[mask]
        y_pix = GY[mask]

        # convert to RA/Dec
        world = wcs.wcs_pix2world(
            np.column_stack((x_pix, y_pix)), 0  # 0 for 0-based pixels
        )
        ra_pts = world[:, 0]
        dec_pts = world[:, 1]
        pts_coords = SkyCoord(ra_pts * u.deg, dec_pts * u.deg)

        # angular distance from facet centre (deg)
        sep_deg = pts_coords.separation(facet_centre).deg
        phase_centre_sep_deg = pts_coords.separation(phase_centre).deg

        # effective averaging in freq & time
        eff_bw = bandwidth_hz * freqavg
        eff_int_1 = integration_time_s * avg_factor
        avg_factor_2 = avg_factor
        if avg_factor_2%2!=0:
            avg_factor_2-=1
        eff_int_2 = integration_time_s * avg_factor_2

        # compute facet smearing (vectorised)
        facet_time_smearing_1, facet_bandwidth_smearing, _ = fluxration_smearing(
            central_freq_hz=central_freq_hz,
            bandwidth_hz=eff_bw,
            integration_time_s=eff_int_1,
            resolution=resolution_arcsec,
            distance_from_phase_center_deg=sep_deg,
        )

        # compute facet smearing 2sec (vectorised)
        facet_time_smearing_2, _, _ = fluxration_smearing(
            central_freq_hz=central_freq_hz,
            bandwidth_hz=eff_bw,
            integration_time_s=eff_int_2,
            resolution=resolution_arcsec,
            distance_from_phase_center_deg=sep_deg,
        )

        # compute central smearing (vectorised)
        total_time_smearing_1, total_bandwidth_smearing, _ = fluxration_smearing(
            central_freq_hz=central_freq_hz,
            bandwidth_hz=bandwidth_hz,
            integration_time_s=integration_time_s,
            resolution=resolution_arcsec,
            distance_from_phase_center_deg=phase_centre_sep_deg,
        )

        # compute central smearing (vectorised)
        total_time_smearing_2, _, _ = fluxration_smearing(
            central_freq_hz=central_freq_hz,
            bandwidth_hz=bandwidth_hz,
            integration_time_s=integration_time_s*2,
            resolution=resolution_arcsec,
            distance_from_phase_center_deg=phase_centre_sep_deg,
        )


        smear_total_grid[mask] = ((facet_time_smearing_1*0.6 + facet_time_smearing_2*0.4)
                                  * facet_bandwidth_smearing
                                  * (total_time_smearing_1*0.6+np.where(total_time_smearing_2>0,total_time_smearing_2, 0)*0.4)
                                  * total_bandwidth_smearing)

        # total_time_smearing_1 = 1.0
        # total_time_smearing_2 = 1.0
        # smear_total_grid[mask] = ((facet_time_smearing_1*1.0 + facet_time_smearing_2*0.0)
        #                           * facet_bandwidth_smearing
        #                           * (total_time_smearing_1*1.0+np.where(total_time_smearing_2>0,total_time_smearing_2, 0)*0.0)
        #                           * total_bandwidth_smearing)


    # ----- Plot result -----
    fig = plt.figure(figsize=(8, 6))
    ax = fig.add_subplot(111, projection=wcs)

    im = ax.imshow(
        smear_total_grid,
        origin="lower",
        extent=[gx.min(), gx.max(), gy.min(), gy.max()],
        cmap=cmap,
        aspect="equal",
        vmin=0.2,
        vmax=1.0,
    )

    # facet outlines
    for patch in all_patches:
        patch.set_edgecolor("black")
        patch.set_facecolor("none")
        ax.add_patch(patch)

    cbar = fig.colorbar(im, ax=ax)
    cbar.set_label("Smearing", fontsize=16)

    ax.set_xlabel("Right Ascension (J2000)", fontsize=16)
    ax.set_ylabel("Declination (J2000)", fontsize=16)
    # ax.set_title("Facet-dependent smearing")
    ax.tick_params(axis="both", which="major", labelsize=14)
    cbar.ax.tick_params(labelsize=14)

    plt.tight_layout()
    plt.savefig("smearing.png", dpi=200)


plot_theoretical_smearing(fits_file='fullFoV_1sec/1.2asec-image.fits',
                          csv_file='/project/lofarvwf/Share/jdejong/output/ELAIS/polygon_info.csv',
                          facets='/project/lofarvwf/Share/jdejong/output/ELAIS/ALL_200h/polygons/facets.reg',
                          central_freq_hz=140e6,
                          bandwidth_hz=12.21e3,
                          integration_time_s=1.0,
                          resolution_arcsec=0.4,
                          grid_res=800,
                          cmap="cividis")
