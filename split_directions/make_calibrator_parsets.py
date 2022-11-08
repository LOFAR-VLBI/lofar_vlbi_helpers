#!/usr/bin/env python

"""Based on script, written by Frits Sweijen"""

from astropy.table import Table
from scipy.cluster.hierarchy import linkage, fcluster
import numpy as np
import casacore.tables as ct
from scipy.spatial import distance
from math import pi


def find_candidates(cat, fluxcut=25e-3):
    ''' Identify candidate sources for DDE calibration.
    The given catalog is searched for potential calibrator sources based on a cut in peak intensity.
    An attempt is made to remove duplicate entries by clustering multiple components based on their
    distance and subsequently assigning that source the average coordinates of the components.
    Args:
        cat (str): filename of the source catalog to use.
        fluxcut (float): lower limit in Jy, of the peak flux density to select on.
    Returns:
        candidates (Table): a table containing candidate sources to phaseshift to. Columns
            that are present, are Source_id, RA and DEC.
    '''
    tab = Table.read(cat)
    sub_tab = tab[tab['Peak_flux'] > fluxcut]
    sub_tab.rename_column('RA', 'RA')
    sub_tab.rename_column('DEC', 'DEC')

    # In case of multiple components of a single source being found, calculate the mean position.
    candidates = Table(names=['Source_id', 'RA', 'DEC'])

    # Make an (N,2) array of directions and compute the distances between points.
    pos = np.stack((list(sub_tab['RA']), list(sub_tab['DEC'])), axis=1)

    # Cluster components based on the distance between them.
    Z = linkage(pos, method='complete', metric='euclidean')
    clusters = fcluster(Z, 1 * 60. / 3600., criterion='distance')

    # Loop over the clusters and merge them into single directions.
    for c in np.unique(clusters):
        idx = np.where(clusters == c)
        i = idx[0][0]
        comps = sub_tab[idx]
        if len(comps) == 1:
            # Nothing needs to merge with this direction.
            candidates.add_row((sub_tab['Source_id'][i], sub_tab['RA'][i], sub_tab['DEC'][i]))
            continue
        else:
            ra_mean = np.mean(sub_tab['RA'][idx])
            dec_mean = np.mean(sub_tab['DEC'][idx])
            if (ra_mean not in candidates['RA']) and (dec_mean not in candidates['DEC']):
                candidates.add_row((sub_tab['Source_id'][i], ra_mean, dec_mean))
            else:
                print('Direction {:d} has been merged already.\n'.format(sub_tab['Source_id'][i]))
    return candidates


def make_parset(ms=None, candidate=None, special=None, prefix=''):
    ''' Create a DPPP ready parset for phaseshifting towards the sources.
    Args:
        fits (Fits): fits file to find phase center
        candidate (Table): candidate.
        special (bool): for some L-numbers they have already been averaged
        prefix (str): prefix to prepend to spit out measurement sets. Default is an empty string.
    Returns:
        parset (str): a fully formatted parset ready to be fed into DPPP.
    '''

    t = ct.table(ms+'::FIELD')
    phasedir = t.getcol("PHASE_DIR").squeeze()
    phasedir *= 180/pi
    sourcedir = np.array([candidate['RA'], candidate['DEC']])

    dist = distance.euclidean(phasedir % 360, sourcedir % 360)

    if dist>2.5:
        return

    parset = 'msin.datacolumn=DATA' \
             '\nmsout.storagemanager=dysco' \
             '\nmsout.writefullresflag=False' \
             '\nsteps=[ps,avg]' \
             '\nps.type=phaseshifter' \
             '\navg.type=averager' \
             '\navg.freqstep=8'

    t = ct.table(ms+'::FIELD')
    phasedir = t.getcol("PHASE_DIR").squeeze()
    phasedir *= 180/pi

    if special:
        parset += '\navg.timestep=2'
    else:
        parset += '\navg.timestep=4'
    parset += '\nmsout.name=' + prefix+'_'+'P{:d}.ms'.format(int(candidate['Source_id']))
    parset += '\nps.phasecenter=' + '[{:f}deg,{:f}deg]\n'.format(candidate['RA'], candidate['DEC'])
    with open(prefix+'P{:d}.parset'.format(int(candidate['Source_id'])), 'w') as f:
        f.write(parset)
    return parset


if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument('--ms', dest='ms', help='Measurement set to read phase dir from')
    parser.add_argument('--catalog', dest='catalog', help='Catalog to select candidate calibrators from.')
    parser.add_argument('--already_averaged_data', dest='special', help='When using special L-numbers that have already been time averaged', action='store_true', default=None)
    parser.add_argument('--prefix', dest='prefix', help='Prefix', default='')

    args = parser.parse_args()

    candidates = find_candidates(args.catalog)

    candidates.write('dde_calibrators.csv', format='ascii.csv', overwrite=True)
    for i, candidate in enumerate(candidates):
        parset = make_parset(ms=args.ms, candidate=candidate, special=args.special, prefix=args.prefix)
