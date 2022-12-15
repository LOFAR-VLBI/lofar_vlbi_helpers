import tables
from glob import glob
import numpy as np
import csv

h5s = glob("P*/scalarphasediffcheck*.h5")

f = open('scalarphase_output.csv', 'w')
writer = csv.writer(f)
writer.writerow(["file", "sin_value"])
for h5 in h5s:
    H = tables.open_file(h5)

    axes = str(H.root.sol000.phase000.val.attrs["AXES"]).replace("b'",'').replace("'",'').split(',')
    freq_ax = axes.index('freq')
    pol_ax = axes.index('pol')
    ant_ax = axes.index('ant')
    dir_ax = axes.index('dir')
    axs = list({freq_ax, pol_ax, ant_ax, dir_ax})[::-1]

    phase = H.root.sol000.phase000.val[:]
    phase_sin = abs(np.sin(phase))
    phase_sin_sum = np.sum(phase_sin)

    # number of data points to normalize
    dpoints = phase.shape[freq_ax]*phase.shape[ant_ax]

    # phase sin sum per time
    for a in axs:
        phase_sin = np.sum(phase_sin, axis=a)
    # normalize
    phase_sin /= dpoints

    writer.writerow([h5, phase_sin_sum])
    H.close()

f.close()
