"""
This script is added to solve a bug from different DDF versions
"""

import os
from glob import glob
import argparse

parser = argparse.ArgumentParser(description='')
parser.add_argument('--path', type=str, help='path')
parser.add_argument('--suffix', type=str, help='endings from files to change')
args = parser.parse_args()

new_hash = glob(args.path+'/*.pre-cal_ddf.h5')[0].split('/')[-1].split('_')[3]
current_hash = glob(args.path+'/*.msdpppconcat')[0].split('/')[-1].split('_')[3]

for ms in glob(args.path+'/*'+args.suffix):
    print(new_hash, current_hash)
    print(ms)
    # os.system('mv '+ms+' '+ms.replace(current_hash, new_hash))