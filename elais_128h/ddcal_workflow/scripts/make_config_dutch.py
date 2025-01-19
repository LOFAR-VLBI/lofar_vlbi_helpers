#!/usr/bin/env python3
# -*- coding: utf-8 -*-

__author__ = "Jurjen de Jong"

from argparse import ArgumentParser
import pandas as pd
import re
from astropy.table import Table
from astropy.coordinates import SkyCoord
from astropy.coordinates import match_coordinates_sky
from astropy import units as u


def parse_source_id(inp_str: str = None):
    """
    Parse ILTJ... source_id string

    Args:
        inp_str: ILTJ source_id

    Returns: parsed output

    """

    parsed_inp = re.findall(r'ILTJ\d+\..\d+\+\d+.\d+', inp_str)[0]

    return parsed_inp

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

def make_directions(cat_6asec: str = None, phasediff_csv: str = None):
    """
    Make directions.txt file as input for the facetselfcal config file

    Args:
        cat_6asec: Catalogue of 6" arcsecond
        phasediff_csv: Phasediff-scores
    """

    phasediff_df = pd.read_csv(phasediff_csv)
    cat_6asec_df = Table.read(cat_6asec)['Peak_flux', 'RA', 'DEC','Isl_rms'].to_pandas()

    # crossmatch catalogues
    crossmatch_df = crossmatch_tables(phasediff_df, cat_6asec_df, 6)

    # filter sources within 0.1 degrees
    crossmatch_df = crossmatch_itself(crossmatch_df)

    with open('directions.txt', 'a+') as d:
        d.write(f'#RA DEC start solints soltypelist_includedir')
        for dir in crossmatch_df.iterrows():

            if dir[1]["Peak_flux"] < 0.075:
                continue

            if dir[1]['Peak_flux'] > 0.3:
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
stop                            = 10
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

def parse_args():
    """
    Command line argument parser

    Returns: parsed arguments
    """

    parser = ArgumentParser(description='Make config for facetselfcal international DD solves')
    parser.add_argument('--catalogue', type=str, help='Catalogue with 6arcsec information')
    parser.add_argument('--phasediff_output', type=str, help='Phasediff CSV output')
    return parser.parse_args()

def main():
    """
    Main function
    """

    args = parse_args()

    make_directions(args.catalogue, args.phasediff_output)
    make_config()

if __name__ == "__main__":
    main()

