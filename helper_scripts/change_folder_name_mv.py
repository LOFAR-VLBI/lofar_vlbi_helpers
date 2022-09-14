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

for ms in glob(args.path+'/*'+args.suffix):
    os.system('mv '+ms+' '+ms.replace('.pre-cal','').replace('A1C14Et', 'A1C14Dt'))