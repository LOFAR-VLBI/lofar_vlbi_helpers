#!/usr/bin/env python

"""Written by Frits Sweijen"""

from astropy.io import ascii
from astropy.table import Table
from scipy.cluster.hierarchy import linkage, fcluster
import ast
import numpy as np


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
    tab = ascii.read(cat)
    sub_tab = tab[tab['Peak_flux'] > fluxcut]
    sub_tab.rename_column('RA', 'LOTSS_RA')
    sub_tab.rename_column('DEC', 'LOTSS_DEC')

    # In case of multiple components of a single source being found, calculate the mean position.
    candidates = Table(names=['Source_id', 'RA', 'DEC'])
    candidates.rename_column('RA', 'LOTSS_RA')
    candidates.rename_column('DEC', 'LOTSS_DEC')

    # Make an (N,2) array of directions and compute the distances between points.
    pos = np.stack((list(sub_tab['LOTSS_RA']), list(sub_tab['LOTSS_DEC'])), axis=1)

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
            candidates.add_row((sub_tab['Source_id'][i], sub_tab['LOTSS_RA'][i], sub_tab['LOTSS_DEC'][i]))
            continue
        else:
            ra_mean = np.mean(sub_tab['LOTSS_RA'][idx])
            dec_mean = np.mean(sub_tab['LOTSS_DEC'][idx])
            if (ra_mean not in candidates['LOTSS_RA']) and (dec_mean not in candidates['LOTSS_DEC']):
                candidates.add_row((sub_tab['Source_id'][i], ra_mean, dec_mean))
            else:
                print('Direction {:d} has been merged already.\n'.format(sub_tab['Source_id'][i]))
    return candidates


def make_parset(candidates, sols_phase=None, solset_phase='sol000', sols_amp=None, solset_amp='sol000', prefix=''):
    ''' Create a DPPP ready parset for phaseshifting towards the sources.
    Args:
        candidates (Table): a table containing the sources to phaseshift to.
        sols_phase (str): path to the h5parm containing phase solutions of the infield calibrator.
        solset_phase (str): name of the solset from which to take phase solutions. Default is `sol000`.
        sols_amp (str): path to the h5parm containing ampliutde solutions of the infield calibrator.
        solset_amp (str): name of the solset from which to take amplitude solutions. Default is `sol000`.
        prefix (str): prefix to prepend to spit out measurement sets. Default is an empty string.
    Returns:
        parset (str): a fully formatted parset ready to be fed into DPPP.
    '''
    parset = '''msout.storagemanager=dysco
steps=[explode]
'''
    if (sols_phase is not None) and (sols_amp is not None):
        parset += '''explode.steps=[shift,avg1,apply1,apply2,adder,filter,averager,msout]
'''
    elif (sols_phase is not None) and (sols_amp is None):
        parset += '''explode.steps=[shift,avg1,apply1,adder,filter,averager,msout]
'''
    elif (sols_phase is None) and (sols_amp is None):
        parset += '''explode.steps=[shift,avg1,adder,filter,averager,msout]
'''

    parset += '''explode.replaceparms = [shift.phasecenter, msout.name]
shift.type=phaseshift
# Average the data a little bit to 4s and 4 ch/SB
avg1.type = average
avg1.timeresolution = 4
avg1.freqresolution = 48.82kHz
'''
    if sols_phase is not None:
        parset += '''apply1.type = applycal
apply1.parmdb = {h5phase:s}
apply1.solset = {h5phasess:s}
apply1.correction = phase000
'''.format(h5phase=sols_phase, h5phasess=solset_phase)
    if sols_amp is not None:
        parset += '''apply2.type = applycal
apply2.parmdb = {h5amp:s}
apply2.solset = {h5ampss:s}
apply2.correction = amplitude000
'''.format(h5amp=sols_amp, h5ampss=solset_amp)
    parset += '''adder.type=stationadder
adder.stations={ST001:'CS*'}
filter.type=filter
filter.baseline=^[C]S*&&
filter.remove=True
# Average the data to 60 s and 1 ch / SB
averager.type=averager
averager.freqresolution = 195.28kHz
averager.timeresolution = 60
msout.overwrite = True
'''
    parset += 'msout.name=[' + ','.join(list(map(lambda s: prefix + 'P{:d}.ms'.format(int(s)), candidates['Source_id']))) + ']\n'
    parset += 'shift.phasecenter=[' + ','.join(list(map(lambda x: '[{:f}deg,{:f}deg]'.format(x[0], x[1]), candidates['RA', 'DEC']))) + ']\n'
    return parset


if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument('--catalog', dest='catalog', help='Catalog to select candidate calibrators from.')
    parser.add_argument('--write-parsets', dest='writepset', help='Write out parsets to do the splitting.', default=False, type=bool)
    parser.add_argument('--prefix', dest='prefix', help='Prefix for the split out measurement sets.', default='')
    parser.add_argument('--solutions_phase', dest='sols_phase', help='Phase solutions on infield calibrator.', default='')
    parser.add_argument('--solset_phase', dest='ss_phase', help='Solset for phase solutions on infield calibrator.', default='sol001')
    parser.add_argument('--solutions_amp', dest='sols_amp', help='Amplitude solutions on infield calibrator.', default='')
    parser.add_argument('--solset_amp', dest='ss_amp', help='Solset for amplitude solutions on infield calibrator.', default='sol001')

    args = parser.parse_args()

    if (args.sols_amp) and (not args.sols_phase):
        parser.error('Cannot specify --solutions_amp without specifying --solutions_phase.')

    candidates = find_candidates(args.catalog)
    candidates.write('dde_calibrators.csv', format='ascii.csv')
    if ast.literal_eval(args.writepset):
        Nchunks = (len(candidates) // 10) + 1
        for i in xrange(Nchunks):
            candidate_chunk = candidates[10 * i:10 * (i + 1)]
            if args.sols_phase:
                parset = make_parset(candidate_chunk, sols_phase=args.sols_phase, solset_phase=args.ss_phase, prefix=args.prefix)
                if args.sols_amp:
                    parset = make_parset(candidate_chunk, sols_phase=args.sols_phase, solset_phase=args.ss_phase, sols_amp=args.sols_amp, solset_amp=args.ss_amp, prefix=args.prefix)
            else:
                parset = make_parset(candidate_chunk, prefix=args.prefix)

            with open('shift_to_calibrators_{:01d}.parset'.format(i), 'w') as f:
                f.write(parset)