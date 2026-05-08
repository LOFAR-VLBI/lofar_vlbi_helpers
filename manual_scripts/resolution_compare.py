from astropy.coordinates import SkyCoord
from astropy import units as u
from astropy.table import Table
from astropy.coordinates import match_coordinates_sky
import numpy as np
from astropy.io import fits
import matplotlib.pyplot as plt


def plot_barchart_with_errors(values, errors, labels=None, title=None, ylabel=None, figsize=(8, 5)):
    """
    Plot a bar chart with error bars.

    Parameters
    ----------
    values : list or np.ndarray
        The heights of the bars.
    errors : list or np.ndarray
        The corresponding error values for each bar.
    labels : list, optional
        Labels for each bar (x-axis tick labels).
    title : str, optional
        Title of the chart.
    ylabel : str, optional
        Label for the y-axis.
    figsize : tuple, optional
        Figure size (width, height).

    Returns
    -------
    matplotlib.figure.Figure
        The generated matplotlib figure.
    """
    values = np.array(values)
    errors = np.array(errors)
    x = np.arange(len(values))

    fig, ax = plt.subplots(figsize=figsize)
    ax.bar(x, values, yerr=errors, capsize=5, color='skyblue', edgecolor='black', alpha=0.8)

    if labels is not None:
        ax.set_xticks(x)
        ax.set_xticklabels(labels, rotation=45, ha='right')

    if title:
        ax.set_title(title, fontsize=12, fontweight='bold')

    if ylabel:
        ax.set_ylabel(ylabel)

    ax.grid(axis='y', linestyle='--', alpha=0.7)
    plt.tight_layout()
    plt.show()

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

values = []
errors = []
labels = []
for f in range(24):
    try:
        c1 = f'/project/lofarvwf/Public/jdejong/ELAIS_200h/facet_{f}/1.2asec/facet_{f}-MFS-image-pb_source_catalog.fits'
        c2 = f'/project/lofarvwf/Public/jdejong/ELAIS_200h/facet_{f}/6asec/facet_{f}-MFS-image-pb_source_catalog.fits'
        flux_threshold = 0.001
        m1, m2 = find_matches(c1, c2, 1)
        mask=((m1['Total_flux']/m2['Total_flux']>0.75) & (m1['Total_flux']/m2['Total_flux']<1.33333)
               & (m1['S_Code']=='S')
               & (m2['S_Code']=='S') & (m1['Total_flux']>flux_threshold))
        m1=m1[mask]
        m2=m2[mask]
        print(f"facet_{f}", round(np.mean(m1['Total_flux']/m2['Total_flux']), 2), round(np.std(m1['Total_flux']/m2['Total_flux']), 2), len(m1))
        values.append(np.mean(m1['Total_flux']/m2['Total_flux']))
        errors.append(np.std(m1['Total_flux']/m2['Total_flux']))
        labels.append(f"facet_{f}")
        # print(m1['Total_flux']/m2['Total_flux'])
    except:
        pass

plot_barchart_with_errors(values, errors, labels, '1.2asec/6asec')