#!/usr/bin/env python

"""Based on script, written by Frits Sweijen"""

from astropy.table import Table
from scipy.cluster.hierarchy import linkage, fcluster
import numpy as np
import casacore.tables as ct
from math import pi
import pyregion
from astropy.io import fits
from astropy import units as u
from astropy.coordinates import SkyCoord
from astropy.wcs import WCS
from astropy.wcs.utils import skycoord_to_pixel

def in_fits(fitsfile, boxfile, coor):
    """
    Check if coor in fitsfile with corresponding boxfile
    :param fitsfile: fitsfile
    :param boxfile: boxfile
    :param coor: coordinate
    :return:
    """
    hdu = fits.open(fitsfile)
    w = WCS(hdu[0].header)
    r = pyregion.open(boxfile).as_imagecoord(header=hdu[0].header)
    mask = r.get_mask(hdu=hdu[0], shape=hdu[0].data[0][0].shape).astype(int)
    c = SkyCoord(ra=coor[0] * u.degree, dec=coor[1] * u.degree, frame='icrs')
    index = [int(i) for i in skycoord_to_pixel(c, wcs=w)]
    if index[0]<mask.shape[0] or index[1]<mask.shape[1] or index[0]>mask.shape[0] or index[1]>mask.shape[1]:
        return False
    return bool(mask[index[0], index[1]])


def find_candidates(cat, ms, fluxcut=25e-3, extra_candidates=[]):
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
    tab = tab[tab['Peak_flux'] > fluxcut]
    tab.rename_column('RA', 'RA')
    tab.rename_column('DEC', 'DEC')

    # In case of multiple components of a single source being found, calculate the mean position.
    candidates = Table(names=['Source_id', 'RA', 'DEC'])

    # Get phase dir of observation
    t = ct.table(ms+'::FIELD')
    phasedir = t.getcol("PHASE_DIR").squeeze()
    phasedir *= 180/pi
    phasedir_coor = SkyCoord(ra=phasedir[0]*u.degree, dec=phasedir[1]*u.degree, frame='fk5')

    # Make an (N,2) array of directions and compute the distances between points.
    pos = np.stack((list(tab['RA']), list(tab['DEC'])), axis=1)

    # Cluster components based on the distance between them.
    Z = linkage(pos, method='complete', metric='euclidean')
    clusters = fcluster(Z, 1 * 60. / 3600., criterion='distance')

    # Loop over the clusters and merge them into single directions.
    for c in np.unique(clusters):
        idx = np.where(clusters == c)
        i = idx[0][0]
        comps = tab[idx]

        # Select only sources within 2.5 degrees box
        sourcedir = np.array([tab['RA'][i], tab['DEC'][i]])
        sourcedir_x = SkyCoord(ra=sourcedir[0]*u.degree, dec=phasedir[1]*u.degree, frame='fk5')
        sourcedir_y = SkyCoord(ra=phasedir[0]*u.degree, dec=sourcedir[1]*u.degree, frame='fk5')

        if phasedir_coor.separation(sourcedir_x).value>1.25 or phasedir_coor.separation(sourcedir_y).value>1.25:
            continue

        if len(comps) == 1:
            # Nothing needs to merge with this direction.
            candidates.add_row((tab['Source_id'][i], tab['RA'][i], tab['DEC'][i]))
            continue
        else:
            ra_mean = np.mean(tab['RA'][idx])
            dec_mean = np.mean(tab['DEC'][idx])
            if (ra_mean not in candidates['RA']) and (dec_mean not in candidates['DEC']):
                candidates.add_row((tab['Source_id'][i], ra_mean, dec_mean))
            else:
                print('Direction {:d} has been merged already.\n'.format(tab['Source_id'][i]))

    for candidate in extra_candidates:
        name, ra, dec = candidate
        candidates.add_row((name, ra, dec))



    return candidates


def make_parset(ms=None, h5=None, candidate=None, prefix='', brighter=False):
    ''' Create a DPPP ready parset for phaseshifting towards the sources.
    Args:
        candidate (Table): candidate.
        prefix (str): prefix to prepend to spit out measurement sets. Default is an empty string.
    Returns:
        parset (str): a fully formatted parset ready to be fed into DPPP.
    '''

    freqband = ms.split('_')[-1].split('.')[0]

    parset = 'msin='+ms
    parset += '\nmsout=' + prefix+'_'+freqband+'_P{:d}.ms'.format(int(candidate['Source_id']))
    if brighter:
        freqres='195.28kHz'
        timeres='8'
    else:
        freqres='390.56kHz'
        timeres='60'

    parset += f'\nmsin.datacolumn=DATA' \
              '\nmsout.storagemanager=dysco' \
              '\nmsout.writefullresflag=False' \
              '\nsteps=[ps,beam,ac,avg]' \
              '\nps.type=phaseshifter' \
              '\navg.type=averager' \
              '\navg.freqresolution=195.28kHz' \
              '\navg.timeresolution=8' \
              '\nbeam.type=applybeam' \
              '\nbeam.updateweights=True' \
              '\nbeam.direction=[]' \
              '\nac.type=applycal' \
              '\nac.parmdb=' + h5 + \
              '\nac.correction=fulljones' \
              '\nac.soltab=[amplitude000,phase000]'


    t = ct.table(ms+'::FIELD')
    phasedir = t.getcol("PHASE_DIR").squeeze()
    phasedir *= 180/pi

    parset += '\nps.phasecenter=' + '[{:f}deg,{:f}deg]\n'.format(candidate['RA'], candidate['DEC'])
    with open(prefix+'_'+freqband+'_P{:d}.parset'.format(int(candidate['Source_id'])), 'w') as f:
        f.write(parset)

    return parset




if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument('--ms', dest='ms', help='Measurement set to read phase dir from')
    parser.add_argument('--h5', dest='h5', help='Delayselfcal solutions')
    parser.add_argument('--catalog', dest='catalog', help='Catalog to select candidate calibrators from.')
    parser.add_argument('--prefix', dest='prefix', help='Prefix', default='')

    args = parser.parse_args()

    candidates = find_candidates(cat=args.catalog, ms=args.ms, extra_candidates=[[99999, 244.0989, 55.4513], [99998, 243.2815, 56.1325]])

    candidates.write('dde_calibrators.csv', format='ascii.csv', overwrite=True)
    for candidate in candidates:
        parset = make_parset(ms=args.ms, candidate=candidate, prefix=args.prefix, h5=args.h5)
