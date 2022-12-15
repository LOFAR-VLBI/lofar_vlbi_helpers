"""
Updated and simplified version from code from Haoyang Ye: https://github.com/zoeye859/lb_scripts/blob/main/paper_scripts/
Rewritten by: Jurjen de Jong
"""

import numpy as np
import os
from astropy.io import fits
import pandas as pd
import matplotlib.pyplot as plt

plt.style.use('bmh')

def findrms(file_name, maskSup=1e-7):
    """
    find the rms of an array, from Cycil Tasse/kMS
    """
    hdul = fits.open(file_name)
    mIn = hdul[0].data
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
        images = glob(dir+'/selfcal_'+dir+'_0*-MFS-image.fits')
        d_sub = []
        rms_sub = []
        for imnum, image in enumerate(images):
            rms_sub.append(findrms(image)*1e3) # mJy/beam
            d_sub.append(max_min_val(image))
        d.append(d_sub)
        rms.append(rms_sub)
        d_name.append(dir)
    return d, d_name, rms

if __name__ == '__main__':

    import argparse
    from glob import glob

    parser = argparse.ArgumentParser(description='Validate selfcal output')
    parser.add_argument('--dirs', nargs='+', help='path to folders with selfcal output', default=None)
    parser.add_argument('--plot_png', help='plot noise pngs', action='store_true')

    args = parser.parse_args()

    if args.dirs is None:
        directions = [d for d in glob('P*') if len(d)==6]
    else:
        directions = args.dirs  # Directory of where all calibrator selfcal fits images are stored

    plot_png = args.plot_png
    d, d_name, rms = collect_val(directions)

    df_dynr = pd.DataFrame(d, index=d_name).T
    df_rms = pd.DataFrame(rms, index=d_name).T
    df_dynr.to_csv(r'dynamic_range.csv', index=False, header=True)
    df_rms.to_csv(r'rms.csv', index=False, header=True)

    images = 'images/'
    os.system('mkdir -p ' + images)

    rdec = []

    for dir in directions:
        rms = df_rms[dir]
        dyn_range = df_dynr[dir]

        dr_origin = dyn_range[0]
        decrease_ratio = ["{:.2%}".format((dr - dr_origin) / dr_origin) for dr in list(dyn_range)]
        decrease_ratio_val = [(dr - dr_origin) / dr_origin for dr in list(dyn_range)]
        rdec.append(decrease_ratio_val)

        if plot_png:

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

    df_rmsdec = pd.DataFrame(rdec, index=d_name)

    df1 = df_dynr.T.rename(columns={c:'C'+str(c) for c in df_dynr.T.columns})
    df2 = df_rmsdec.rename(columns={c:str(c) for c in df_dynr.T.columns})
    val_max = df1.max(axis = 1, skipna = True).tolist()
    ind_max = df1.idxmax(axis = 1, skipna = True).tolist()
    df1['C val_max'] = val_max
    df1['C ind_max'] = ind_max
    val_min = df2.min(axis = 1, skipna = True).tolist()
    ind_min = df2.idxmin(axis = 1, skipna = True).tolist()
    df2['val_min'] = val_min
    df2['ind_min'] = ind_min
    result = pd.concat([df2, df1], axis=1, join="inner")
    result['val_min_compare'] = result['0'] - result['val_min']
    result['h5_num'] = [i for i in result['C ind_max']]
    #### 4 conditions
    con1 = result['C val_max'] > result['C0'] # max/min increase from C0
    con2 = result['ind_min'] != str(0) # the biggest decrease should not be here
    con3 = result['C val_max'] > 30
    con4 = result['val_min'] < -0.1
    #con5 = result['val_min_compare'] > 0.06
    #### filter
    select = result.loc[con1 & con2 & con3 & con4]
    h5_num_filter = select['h5_num'].tolist()
    dir_num_filter = select.index.tolist()
    Max_min_filter = select['C val_max'].tolist()
    result.to_hdf('result.h5', key='result', mode='w')
    select.to_hdf('select.h5', key='select', mode='w')

    print('We choose ' + str(len(dir_num_filter)) + ' calibrators, and their numbers are:')
    os.system('mkdir -p best_solutions')

    for i in range(len(dir_num_filter)):
        print(dir_num_filter[i], h5_num_filter[i])
        os.system('cp ' + sorted(glob(dir_num_filter[i] + '/merged_addCS_selfcal*'))[-1] + 'best_solutions')
