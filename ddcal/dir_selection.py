"""
Updated and simplified version from code from Haoyang Ye: https://github.com/zoeye859/lb_scripts/blob/main/paper_scripts/
Rewritten by: Jurjen de Jong
"""

import numpy as np
import os
from astropy.io import fits
import pandas as pd
import matplotlib.pyplot as plt
import csv
import tables
from scipy.stats import circstd
import sys

plt.style.use('bmh')

def findrms(file_name, maskSup=1e-7):
    """
    find the rms of an array, from Cycil Tasse/kMS
    """
    hdul = fits.open(file_name)
    mIn = np.ndarray.flatten(hdul[0].data)
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
    hdul.close()

    return rms


def max_min_val(file_name):
    """
    :param file_name: fits file name
    :return: pixel max/min value
    """
    print('Opening file ', file_name)
    hdul = fits.open(file_name)
    data = hdul[0].data
    val = np.abs(data.max() / data.min())
    hdul.close()
    return val

def collect_val(directions):
    """
    :param directions: list with directions
    :return: lists with max_min_values, source_names, rms
    """
    d = []
    d_name = []
    rms = []
    for dir_num, dir in enumerate(directions):
        images = sorted(glob(dir+'/selfcal_'+dir+'_0*-MFS-image.fits'))
        d_sub = []
        rms_sub = []
        for imnum, image in enumerate(images):
            rms_sub.append(findrms(image)*1e3) # mJy/beam
            d_sub.append(max_min_val(image))
        d.append(d_sub)
        rms.append(rms_sub)
        d_name.append(dir)
    return d, d_name, rms

def scalarphasediff(h5s=None):

    if h5s is None:
        h5s = glob("P*_scalarphasediff/scalarphasediff0*.h5")

    f = open('scalarphasediff_output.csv', 'w')
    writer = csv.writer(f)
    writer.writerow(["file", "circ_score"])
    for h5 in h5s:
        print(h5.split("_")[0])
        std, _ = get_scalarphasediff_measure(h5)
        print(std)
        writer.writerow([h5.split("_")[0], std])

    f.close()

def gonio_score(phasemod):
    phasemod %= (2 * np.pi)
    p = np.zeros(phasemod.shape)
    p += np.where((phasemod < np.pi / 2) | ((phasemod < 2 * np.pi) & (phasemod > 3 * np.pi / 2)),
                  np.abs(np.sin(phasemod)), 0)
    p += np.where((phasemod < 3 * np.pi / 2) & (phasemod > np.pi / 2), 1 + np.abs(np.cos(phasemod)), 0)
    return p


def get_scalarphasediff_measure(h5):
    H = tables.open_file(h5)

    stations = list(H.root.sol000.antenna[:]['name'])
    distant_stations_idx = [stations.index(station) for station in stations if
                            ('RS' not in station) &
                            ('ST' not in station) &
                            ('CS' not in station) &
                            ('DE' not in station)]

    axes = str(H.root.sol000.phase000.val.attrs["AXES"]).replace("b'", '').replace("'", '').split(',')
    axes_idx = sorted({ax: axes.index(ax) for ax in axes}.items(), key=lambda x: x[1], reverse=True)

    phase = H.root.sol000.phase000.val[:]
    H.close()

    phasemod = phase % (2 * np.pi)

    for ax in axes_idx:
        if ax[0] == 'pol':  # YX should be zero
            phasemod = phasemod.take(indices=0, axis=ax[1])
        elif ax[0] == 'dir':  # there should just be one direction
            if phasemod.shape[ax[1]] == 1:
                phasemod = phasemod.take(indices=0, axis=ax[1])
            else:
                sys.exit('ERROR: This solution file should only contain one direction, but it has ' +
                         str(phasemod.shape[ax[1]]) + ' directions')
        elif ax[0] == 'time':  # faraday corrected
            phasemod = np.diff(np.diff(phasemod, axis=ax[1]))
        elif ax[0] == 'ant':  # take only international stations
            phasemod = phasemod.take(indices=distant_stations_idx, axis=ax[1])

    gonio_sc = gonio_score(phasemod)

    return circstd(phasemod), np.mean(gonio_sc)

if __name__ == '__main__':

    import argparse
    from glob import glob

    parser = argparse.ArgumentParser(description='Validate selfcal output')
    parser.add_argument('--dirs', nargs='+', help='path to folders with selfcal output', default=None)
    parser.add_argument('--plot_png', help='plot noise pngs', action='store_true')

    args = parser.parse_args()

    if args.dirs is None:
        directions = [d for d in glob('P*') if len(d)==6]
        scalarphasediff()
    else:
        directions = args.dirs  # Directory of where all calibrator selfcal fits images are stored
        h5s = glob("P*_scalarphasediff/scalarphasediff0*.h5")
        scalarphasediff_h5s = [d for d in h5s if d[0:6] in directions]
        scalarphasediff(scalarphasediff_h5s)

    plot_png = args.plot_png
    d, d_name, rms = collect_val(directions)

    df_dynr = pd.DataFrame(d, index=d_name)
    df_rms = pd.DataFrame(rms, index=d_name)
    df_dynr.to_csv(r'dynamic_range.csv', index=True, header=True)
    df_rms.to_csv(r'rms.csv', index=True, header=True)

    if plot_png:

        images = 'images/'
        os.system('mkdir -p ' + images)

        rdec = []

        for dir in directions:
            rms = df_rms.T[dir]
            dyn_range = df_dynr.T[dir]

            dr_origin = dyn_range[0]
            decrease_ratio = ["{:.2%}".format((dr - dr_origin) / dr_origin) for dr in list(dyn_range)]
            decrease_ratio_val = [(dr - dr_origin) / dr_origin for dr in list(dyn_range)]
            rdec.append(decrease_ratio_val)

            plt.plot(rms)
            plt.title(dir)
            plt.savefig(images+'/rms_'+dir+'.png')
            plt.close()

            plt.plot(dyn_range)
            plt.title(dir)
            plt.savefig(images+'/dynamicrange_'+dir+'.png')
            plt.close()

            plt.plot(decrease_ratio_val)
            plt.title(dir)
            plt.savefig(images+'/rms_ratio_'+dir+'.png')
            plt.close()

    t = pd.read_csv('scalarphasediff_output.csv')

    rms = df_rms.rename(columns={c: 'rms_c' + str(c) for c in df_rms.columns})
    dr = df_dynr.rename(columns={c: 'dr_c' + str(c) for c in df_dynr.columns})

    dr['dr_max'] = dr.max(axis=1)
    t = t.set_index('file').merge(rms, left_index=True, right_index=True).merge(dr, left_index=True, right_index=True)
    t['rms_ratio'] = t['rms_c0'] / t['rms_c11']
    t['dr_ratio'] = t['dr_c0'] / t['dr_c11']
    t = t[['circ_score', 'rms_ratio', 'dr_ratio', 'dr_max']]
    t.to_csv('value_analyses.csv')
    c1 = t['circ_score'] < 2.15
    c2 = t['rms_ratio'] > 0.8
    c3 = t['dr_max'] > 20
    c4 = t['dr_ratio'] < 0.9
    cond = c1 | (c2 & c3 & c4)
    selection = t[cond]
    selection.to_csv('selected.csv')
    dir_num_filter = selection.index.tolist()

    print('We choose ' + str(len(dir_num_filter)) + ' calibrators, and their numbers are:')
    os.system('mkdir -p best_solutions')

    for d in dir_num_filter:
        os.system('cp ' + sorted(glob(d + '/merged_addCS_selfcal*'))[-1] + ' best_solutions')

    os.system('python /home/lofarvwf-jdejong/scripts/lofar_helpers/h5_merger.py -in best_solutions/*.h5 -out master_merged.h5')
    print('See master_solutions.h5 as final output')
