import tables
from glob import glob
import numpy as np
import csv
from scipy.stats import circstd, circmean
import sys


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
        elif ax[0] == 'freq':  # faraday corrected
            phasemod = np.diff(phasemod, axis=ax[1])
        elif ax[0] == 'ant':  # take only international stations
            phasemod = phasemod.take(indices=distant_stations_idx, axis=ax[1])

    return circstd(phasemod)


h5s = glob("P*_scalarphasediff/scalarphasediff0*.h5")

f = open('scalarphasediff_output.csv', 'w')
writer = csv.writer(f)
writer.writerow(["file", "circ_score"])
for h5 in h5s:
    print(h5.split("_")[0])
    std = get_scalarphasediff_measure(h5)
    print(std)
    writer.writerow([h5.split("_")[0], std])

f.close()
