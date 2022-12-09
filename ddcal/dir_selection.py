# python 3
# Author: Haoyang Ye
# This jupyter notebook combines the python script Noise_extract.py, max_min_extract.py and good_dir_filter.py

import numpy as np
import os
import re
import matplotlib.pylab as plt
import csv
from astropy.io import fits
from pathlib import Path
import pandas as pd
import math
from datetime import datetime
import sys


def now_time():
    now = datetime.now()
    dt_string = now.strftime("%d-%m-%Y_%H-%M-%S")
    print("date and time =", dt_string)
    return dt_string


def max_min_val(file_name):
    print('Opening file ', file_name)
    hdul = fits.open(file_name)
    data = hdul[0].data
    val = np.abs(data.max() / data.min())
    hdul.close()
    return val


def collect_val(dir_num, PATH, d):
    """
    dir_num: str, number of directions
    """
    d['dir_num'][int(dir_num)] = int(dir_num)
    for filename in os.listdir(PATH):
        if filename.startswith(dir_num + '_') and filename.endswith('.fits'):
            val = max_min_val(PATH + filename)
            idx = Path(filename).stem.split('_')[-1]
            d[idx][int(dir_num)] = val
            print(filename, idx, val)
    return d


def init_d(keylist, dir_sum):
    d = {}
    for i in keylist:
        d[i] = [math.nan] * (dir_sum + 1)
    return d


def read_noise(save_PATH, filename):
    noise_output = []
    number_output = []
    with open(filename, 'r') as outfile:
        for line in outfile:
            if line.startswith('  input MS:'):
                ms_file = line[:-1].split('/')[-1]
                # noise_output = [line[:-1].split('/')[-1]]
                # number_output = [line[:-1].split('/')[-1]]
                break
            else:
                ms_file = '0'
    with open(filename, 'r') as outfile:
        for line in outfile:
            if line.startswith(' == Deconvolving ('):
                temp_str = line[:-1]
                temp_num = int(re.search(r'\d+', temp_str).group())
            if line.startswith('Estimated standard deviation of background noise:'):
                noise_output += [temp_str, line[:-1]]
                number_output += [temp_num, float(re.findall(r'[\d\.\d]+', line)[0])]
    print('The ms is: ', ms_file, '\n')
    print('The following list is saved as ' + ms_file + '_noise_output.txt \n', noise_output)
    print('The following list is saved as ' + ms_file + '_noise_data.txt \n', number_output)
    file_output = save_PATH + str(dir_num) + '_' + ms_file + '_noise_output.txt'
    file_data = save_PATH + str(dir_num) + '_' + ms_file + '_noise_data.txt'
    with open(file_output, 'w') as f:
        for item in noise_output:
            f.write("%s\n" % item)
    with open(file_data, 'w') as f:
        for item in number_output:
            f.write("%s\n" % item)
    return ms_file, number_output


def splitevenodd(input_list):
    return input_list[::2], input_list[1::2]


def split_cycle(input_list):
    split_output = []
    temp_idx = 0
    for i in range(1, len(input_list)):
        if input_list[i] == 1:
            split_output = split_output + [input_list[temp_idx:i]]
            temp_idx = i
    split_output = split_output + [input_list[temp_idx:]]
    return split_output


def dir_number_from_filename(filename):
    return int(re.search(r'\d+', filename).group())


def dir_number_from_slurmout(filename):
    print(filename)
    with open(filename, 'r') as outfile:
        for line in outfile:  # '  input MS:       /tmp/26_ILTJ160623.53+540555.9_concat/ILTJ160623.53+540555.9_concat.ms\n'
            if line.startswith('  input MS:'):
                dir_num = line[:-1].split('/')[-2].split('_')[0]
                if dir_num == 'testimg':  # '  input MS:       /tmp/testimg/ILTJ160903.09+561316.8_concat.ms\n'
                    dir_num = 0
                break
            else:
                dir_num = 0
    return int(dir_num)


keylist = ['dir_num', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9']
PATH = '/net/rijn2/data2/Haoyang/ALICE/selfcal_2022/fits_collection/'  # Directory of where all calibrator selfcal fits images are stored
# PATH = str(Path().absolute()).split("\/")[0] + '/fits_collection/' # Directory of current working directory
save_PATH = str(Path().absolute()).split("\/")[0] + '/data_analysis/'
dir_sum = 100  # this number should be larger than the number of calibrator candidates

isExist = os.path.exists(save_PATH)
if not isExist:
    # Create a new directory because it does not exist
    os.makedirs(save_PATH)
    print("The new directory /data_analysis/ is created!")

d = init_d(keylist, dir_sum)
for i in range(1, dir_sum + 1):
    print(i)
    d = collect_val(str(i), PATH, d)

df = pd.DataFrame(dict([(k, pd.Series(v)) for k, v in d.items()]))

df.to_hdf(save_PATH + 'max_min_fits.h5', key='selfcal_1b1', mode='w')

df.to_csv(save_PATH + r'max_min_fits.csv', index=False, header=True)

## Results
df_maxmin = pd.read_hdf(save_PATH + 'max_min_fits.h5')
ratio_table = df_maxmin.T

print(df_maxmin)

print(ratio_table)

markers = ['o', 'v', '^', '<', '>', 's', 'p', 'P', '*', 'X', 'D']
keylist = ['dir_num', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9']
noise_PATH = save_PATH + 'noise_png/'
plot_png = 1
isExist = os.path.exists(noise_PATH)
if not isExist:
    # Create a new directory because it does not exist
    os.makedirs(noise_PATH)
    print("The new directory noise_png is created!")

output_PATH = '/net/rijn2/data2/Haoyang/ALICE/selfcal_2022/'  # where multiple slurm outputs are for each calibrators

d = init_d(keylist, dir_sum)












