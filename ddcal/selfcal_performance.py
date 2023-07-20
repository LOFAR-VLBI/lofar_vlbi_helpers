import numpy as np
from astropy.io import fits
import matplotlib.pyplot as plt
from glob import glob
import re
import csv

plt.style.use('ggplot')

def findrms(fitsfile, maskSup=1e-7):
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

    return rms


def max_min_val(fitsfile):
    """
    Get max/min value

    :param file_name: fits file name
    :return: pixel max/min value
    """
    hdul = fits.open(fitsfile)
    data = hdul[0].data
    val = np.abs(data.max() / data.min())
    hdul.close()
    return val

def get_cycle_num(fitsfile):
    """
    Parse cycle number

    :param fitsfile: fits file name
    """
    return int(float(re.findall("\d{3}", fitsfile)[0]))


if __name__ == '__main__':

    fitsfiles = sorted(glob("*MFS-I-image.fits"))

    f = open('selfcal_performance.csv', 'w')
    writer = csv.writer(f)
    writer.writerow(['cycle', 'rms', 'maxmin'])

    cycles, rmss, maxmins = [], [], []
    for fts in fitsfiles:
        cycle_number, rms, maxmin = get_cycle_num(fts), findrms(fts), max_min_val(fts)
        cycles.append(cycle_number)
        rmss.append(rms)
        maxmins.append(maxmin)
        print(f'cycle: {cycle_number}, rms: {rms}, max/min: {maxmin}')
        writer.writerow([cycle_number, rms, maxmin])
    f.close()

    fig, ax1 = plt.subplots()

    color = 'tab:red'
    ax1.set_xlabel('cycle')
    ax1.set_ylabel('rms', color=color)
    ax1.plot(cycles, rmss, color=color)
    ax1.tick_params(axis='y', labelcolor=color)

    ax2 = ax1.twinx()  # instantiate a second axes that shares the same x-axis

    color = 'tab:blue'
    ax2.set_ylabel('max/min', color=color)  # we already handled the x-label with ax1
    ax2.plot(cycles, maxmins, color=color)
    ax2.tick_params(axis='y', labelcolor=color)

    fig.tight_layout()  # otherwise the right y-label is slightly clipped
    plt.savefig("selfcal_performance.png")



