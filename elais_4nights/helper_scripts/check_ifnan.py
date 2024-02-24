import casacore.tables as ct
import numpy as np
import argparse

parser = argparse.ArgumentParser(description='')
parser.add_argument('--msfile', nargs='+', help='A measurement set.')

args = parser.parse_args()

t = ct.table(args.msfile)

data=t.getcol("DATA")
flag=t.getcol("FLAG")
inv_flag = np.logical_not(flag).astype(int)

if np.sum(np.isnan(data)*inv_flag)>0:
    print('There are NaN values')

if np.sum(np.isinf(data)*inv_flag)>0:
    print('There are infinite values')