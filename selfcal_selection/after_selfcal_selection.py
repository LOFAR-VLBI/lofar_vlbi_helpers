"""
Script used to select selfcals after running facetselfcal.py
This script is complementary to the phasediff selection.

The right order to select directions for widefield imaging is:
1) Run phasediff pre-selection
2) Run facetselfcal on all selected directions
3) Run this script to do a final selection based on the facetselfcal output

Example run:
python selfcal_selection.py --dirs <YOUR_DIRECTIONS>
"""

import numpy as np
from astropy.io import fits
import matplotlib.pyplot as plt
from glob import glob
import re
import csv
import argparse
from scipy.stats import linregress

plt.style.use('ggplot')
plt.rcParams['axes.facecolor']='w'

def get_rms(fitsfile, maskSup=1e-7):
    """
    find the rms of an array, from Cycil Tasse/kMS

    :param fitsfile: fits file name
    :param maskSup: mask threshold
    """
    hdul = fits.open(fitsfile)
    mIn = np.ndarray.flatten(hdul[0].data)
    m=mIn[np.abs(mIn)>maskSup]
    rmsold=np.std(m)
    diff=1e-1
    cut=3.
    med=np.median(m)
    for i in range(10):
        ind=np.where(np.abs(m-med)<rmsold*cut)[0]
        rms=np.std(m[ind])
        if np.abs((rms-rmsold)/rmsold)<diff: break
        rmsold=rms
    hdul.close()

    return rms # jy/beam


def get_minmax(fitsfile):
    """
    Get min/max value

    :param file_name: fits file name
    :return: pixel min/max value
    """
    hdul = fits.open(fitsfile)
    data = hdul[0].data
    val = np.abs(data.min() / data.max())
    hdul.close()
    return val

def get_cycle_num(fitsfile):
    """
    Parse cycle number

    :param fitsfile: fits file name
    """
    return int(float(re.findall("\d{3}", fitsfile.split('/')[-1])[0]))


if __name__ == '__main__':

    parser = argparse.ArgumentParser(description='Validate selfcal output')
    parser.add_argument('--dirs', nargs='+', help='selfcal folder(s)', default=None)

    args = parser.parse_args()

    if args.dirs is None:
        dirfolders = glob('P?????')
    else:
        dirfolders = args.dirs

    g = open('selfcal_performance.csv', 'w')
    writer_all = csv.writer(g)
    writer_all.writerow(['source', 'rms_slope', 'minmax_slope', 'best_cycle', 'accept'])

    for dirpath in dirfolders:

        fitsfiles = sorted(glob(dirpath+"/*MFS-I-image.fits"))
        if len(fitsfiles)==0:
            fitsfiles = sorted(glob(dirpath + "/*MFS-image.fits"))
        dirname = dirpath.split('/')[-1]

        f = open('selfcal_performance_'+dirname+'.csv', 'w')
        writer = csv.writer(f)
        writer.writerow(['cycle', 'rms', 'minmax'])

        # GET CYCLES, RMS, AND MINMAX
        cycles, rmss, minmaxs = [], [], []
        for fts in fitsfiles:
            cycle_number, rms, minmax = get_cycle_num(fts), get_rms(fts), get_minmax(fts)
            cycles.append(cycle_number)
            rmss.append(rms)
            minmaxs.append(minmax)
            print(f'{dirname}\ncycle: {cycle_number}, rms: {rms}, min/max: {minmax}')
            writer.writerow([cycle_number, rms, minmax])
        f.close()
        rmss = list(np.array(rmss)/rmss[0])

        # PLOT
        fig, ax1 = plt.subplots()

        color = 'tab:red'
        ax1.set_xlabel('cycle')
        ax1.set_ylabel('$RMS/RMS_{0}$', color=color)
        ax1.plot(cycles, rmss, color=color)
        ax1.tick_params(axis='y', labelcolor=color)

        ax2 = ax1.twinx()

        color = 'tab:blue'
        ax2.set_ylabel('$|min/max|$', color=color)
        ax2.plot(cycles, minmaxs, color=color)
        ax2.tick_params(axis='y', labelcolor=color)

        ax1.grid(False)
        ax1.grid('off')
        ax2.grid(False)
        ax2.grid('off')
        fig.tight_layout()
        plt.savefig('selfcal_performance_'+dirname+'.png', dpi=300)

        # SCORING
        best_rms_cycle, best_minmax_cycle = np.array(rmss[1:]).argmin()+1, np.array(minmaxs[1:]).argmin()+1
        # using maxmin instead of minmax due to easier slope value to work with
        rms_slope, maxmin_slope = linregress(cycles, rmss).slope, linregress(cycles, 1/np.array(minmaxs)).slope

        # accept direction or not
        if maxmin_slope > 10:
            accept = True
        elif maxmin_slope < 0 and rms_slope > 0:
            accept = False
        elif maxmin_slope < 1.5:
            accept = False
        elif maxmin_slope < 2 and rms_slope >= 0:
            accept = False
        else:
            accept = True

        # choose best cycle
        if best_rms_cycle==best_minmax_cycle:
            bestcycle = best_rms_cycle
        elif rmss[best_minmax_cycle]<=1.1:
            bestcycle = best_minmax_cycle
        elif minmaxs[best_rms_cycle]/minmaxs[0]<=1:
            bestcycle = best_rms_cycle
        else:
            bestcycle = max(best_minmax_cycle, best_rms_cycle)

        writer_all.writerow([dirname, rms_slope, maxmin_slope, bestcycle, int(accept)])

    g.close()


