import os

import argparse
from glob import glob

parser = argparse.ArgumentParser(description='Validate selfcal output')
parser.add_argument('--dirs', nargs='+', help='path to folders with selfcal output', default=None)
args = parser.parse_args()

print(args.dirs)

for dir in args.dirs:
    print(dir)
    os.system('cp ' + sorted(glob(dir + '/merged_addCS_selfcal*'))[-1] + ' best_solutions')

os.system('python /home/lofarvwf-jdejong/scripts/lofar_helpers/h5_merger.py -in best_solutions/*.h5 -out master_merged.h5')