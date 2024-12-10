"""
This script is added to solve a bug from different DDF versions
"""

import os
from glob import glob
import argparse

parser = argparse.ArgumentParser(description='')
parser.add_argument('--path', type=str, help='path')
args = parser.parse_args()

for ms in glob(args.path+'/*.pre-cal.ms'):
    os.system('cp -r '+ms+' '+ms.replace('.pre-cal',''))