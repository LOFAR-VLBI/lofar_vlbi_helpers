import tables
from glob import glob
import numpy as np
import csv

def get_scalarphasediff_measure(h5):
    H = tables.open_file(h5)

    axes = str(H.root.sol000.phase000.val.attrs["AXES"]).replace("b'",'').replace("'",'').split(',')
    freq_ax = axes.index('freq')
    pol_ax = axes.index('pol')
    ant_ax = axes.index('ant')
    dir_ax = axes.index('dir')
    axs = list({freq_ax, pol_ax, ant_ax, dir_ax})[::-1]

    phase = H.root.sol000.phase000.val[:]
    """With the following method we check if a phase angle is noisy.
    By taking modulus 2pi all values are between 0 and 2pi.
    Phases between 0 and pi/2 and between 3pi/2 and 2pi are mapped to the same values with the sinus value.
    Phases between pi/2 and 3pi/2 are most distant and mapped to cos(value)+1, as these are 1 integrand further."""
    phasemod = phase % (2 * np.pi)
    p = np.zeros(phasemod.shape)
    p += np.where((phasemod < np.pi / 2) | ((phasemod < 2 * np.pi) & (phasemod > 3 * np.pi / 2)),
                  np.abs(np.sin(phasemod)), 0)
    p += np.where((phasemod < 3 * np.pi / 2) & (phasemod > np.pi / 2), 1 + np.abs(np.cos(phasemod)), 0)

    # number of data points to normalize
    dpoints = phase.shape[freq_ax]*phase.shape[ant_ax]

    # sum per time
    for a in axs:
        p = np.sum(p, axis=a)

    # normalize
    p /= dpoints
    H.close()

    return np.mean(p), np.min(p), np.max(p)

h5s = glob("P*_scalarphasediff/scalarphasediff0*.h5")

f = open('scalarphasediff_output.csv', 'w')
writer = csv.writer(f)
writer.writerow(["file", "mean_xydiff", "min_xydiff", "max_xydiff"])
for h5 in h5s:
    print(h5.split("_")[0])
    pmean, pmin, pmax = get_scalarphasediff_measure(h5)

    writer.writerow([h5.split("_")[0], pmean, pmin, pmax])

f.close()
