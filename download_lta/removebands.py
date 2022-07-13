from glob import glob
import os
import argparse
import casacore.tables as ct

parser = argparse.ArgumentParser(description='.')
parser.add_argument('--datafolder', type=str, help='path')
parser.add_argument('--freqcut', type=float, help='input data')
args = parser.parse_args()

for ms in glob(args.datafolder):
    if ct.taql('SELECT CHAN_FREQ, CHAN_WIDTH FROM ' + ms + '::SPECTRAL_WINDOW').getcol('CHAN_FREQ')[0]>168:
        os.system('rm -rf ' + ms)