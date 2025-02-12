#!/usr/bin/env python3
# -*- coding: utf-8 -*-

__author__ = "Jurjen de Jong"

from argparse import ArgumentParser
import re
from astropy.table import Table
from astropy.coordinates import SkyCoord
from astropy.coordinates import match_coordinates_sky
from astropy import units as u
from casacore.tables import table
import numpy as np


def parse_source_id(inp_str: str = None):
    """
    Parse ILTJ... source_id string

    Args:
        inp_str: ILTJ source_id

    Returns: parsed output

    """

    parsed_inp = re.findall(r'ILTJ\d+\..\d+\+\d+.\d+', inp_str)[0]

    return parsed_inp


def filter_sources_by_distance(df, ra_col='RA', dec_col='DEC', flux_col='Peak_flux', max_distance=0.15):
    """Select only sources <max_distance from each other"""

    # Sort by Peak_flux in descending order
    df = df.sort_values(by=flux_col, ascending=False).reset_index(drop=True)

    # Make a boolean array to track which sources are excluded
    excluded = np.zeros(len(df), dtype=bool)

    coords = SkyCoord(ra=df[ra_col].values * u.deg, dec=df[dec_col].values * u.deg)

    # Iterate through the sources
    for i, coord in enumerate(coords):
        if excluded[i]:
            continue  # Skip if the source is already excluded

        # Calculate distances to all other sources
        distances = coord.separation(coords).deg

        # Exclude all sources within the max_distance (excluding itself)
        close_sources = (distances < max_distance) & (distances > 0)  # Exclude itself by filtering out 0 distance

        # Mark close sources as excluded
        excluded[close_sources] = True

    # Return the filtered DataFrame
    return df[~excluded].reset_index(drop=True)


def crossmatch_tables(catalog1, catalog2, separation_asec):
    """
    Crossmatching between two tables

    Args:
        catalog1: first catalogue
        catalog2: second catalogue
        separation_asec: separation in arcseconds

    Returns: inner crossmatched 1, inner crossmatched 2
    """

    # Define the celestial coordinates for each catalog
    coords1 = SkyCoord(ra=catalog1['RA'], dec=catalog1['DEC'], unit=(u.deg, u.deg))
    coords2 = SkyCoord(ra=catalog2['RA'], dec=catalog2['DEC'], unit=(u.deg, u.deg))
    idx_catalog2, separation, _ = match_coordinates_sky(coords1, coords2)

    # Maximum separation threshold
    max_sep_threshold = separation_asec * u.arcsec
    matched_sources_mask = separation < max_sep_threshold

    # Filter the matched sources in catalog1
    # matched_sources_catalog1 = catalog1.iloc[matched_sources_mask]
    matched_sources_catalog2 = catalog2.iloc[idx_catalog2[matched_sources_mask]]

    return matched_sources_catalog2


def crossmatch_itself(catalog, min_sep=0.1):
    """
    Crossmatch a table with itself to filter on too close neighbours

    Args:
        catalog: catalogue
        min_sep: minimal separation in degrees

    Returns: filtered catalog
    """

    coords = SkyCoord(ra=catalog['RA'], dec=catalog['DEC'], unit=(u.deg, u.deg))
    idx_catalog, separation, _ = match_coordinates_sky(coords, coords, nthneighbor=2)
    nearest_neighbour = separation<min_sep*u.deg

    return catalog[~nearest_neighbour]


def make_directions(cat_6asec: str = None, radec: list = None):
    """
    Make directions.txt file as input for the facetselfcal config file

    Args:
        cat_6asec: Catalogue of 6" arcsecond
        radec: RA, DEC in list
    """

    ra, dec = radec
    T = Table.read(cat_6asec)['Peak_flux', 'RA', 'DEC','Isl_rms'].to_pandas()
    T.RA %= 360
    T.DEC %= 360

    # Assuming 2.5 degrees box
    T = filter_sources_by_distance(T[(T.RA < ra + 1.25) & (T.RA > ra - 1.25) & (T.DEC < dec + 1.25) & (T.DEC > dec - 1.25)])

    with open('directions.txt', 'a+') as d:
        d.write(f'#RA DEC start solints soltypelist_includedir\n')
        for dir in T.iterrows():

            if dir[1]["Peak_flux"] < 0.06:
                continue

            if dir[1]['Peak_flux'] > 0.15:
                solint="['16s','64s','20min']"
            else:
                solint="['32s','64s','40min']"
            d.write(f"{dir[1]['RA']} {dir[1]['DEC']} 0 {solint} [True,True,True]\n")


def make_config():
    """
    Create facetselfcal config file for DDE calibration at 6"
    """

    solints = "['16s','64s','20min']"

    config=f"""imagename                       = "dutch_6asec"
DDE                             = True
uvminim                         = 10
imsize                          = 9216
noarchive                       = True
forwidefield                    = True
soltype_list                    = ['scalarphase','scalarphase','scalarcomplexgain']
solint_list                     = {solints}
nchan_list                      = [1,1,1]
soltypecycles_list              = [0,0,1]
smoothnessconstraint_list       = [20.,40.,10.]
pixelscale                      = 1.0
niter                           = 60000
robust                          = -0.75
paralleldeconvolution           = 1200
stop                            = 4
multiscale                      = True
parallelgridding                = 5
multiscale_start                = 0
antennaconstraint_list          = [None,None,None]
resetsols_list                  = ['core',None,None]
removeinternational             = True
removemostlyflaggedstations     = True
useaoflagger                    = True
aoflagger_strategy              = "default_StokesV.lua"
channelsout                     = 12
fitspectralpol                  = 5
"""

    # write to file
    with open("dutch_config.txt", "w") as f:
        f.write(config)


def get_ra_dec(ms):
    """
    Get RA/DEC from MS centre

    Args:
        ms: MeasurementSet

    Returns: RA, DEC

    """
    with table(ms+"::FIELD", ack=False) as t:
        ra, dec = np.degrees(t.getcol("PHASE_DIR")).squeeze() % 360
        return ra, dec


def parse_args():
    """
    Command line argument parser

    Returns: parsed arguments
    """

    parser = ArgumentParser(description='Make config for facetselfcal international DD solves')
    parser.add_argument('--catalogue', type=str, help='Catalogue with 6arcsec information')
    parser.add_argument('--ms', type=str, help='MeasurementSet')
    return parser.parse_args()


def main():
    """
    Main function
    """

    args = parse_args()

    ra, dec = get_ra_dec(args.ms)
    make_directions(args.catalogue, [ra, dec])
    make_config()

if __name__ == "__main__":
    main()

