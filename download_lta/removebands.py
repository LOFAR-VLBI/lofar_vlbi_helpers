from glob import glob
import os
import argparse
import casacore.tables as ct

parser = argparse.ArgumentParser(description='.')
parser.add_argument('--datafolder', type=str, help='path')
parser.add_argument('--freqcut', type=float, help='input data', default=168.0)
args = parser.parse_args()

for ms in glob(args.datafolder+'/*.MS'):
    if ct.taql('SELECT CHAN_FREQ, CHAN_WIDTH FROM ' + ms + '::SPECTRAL_WINDOW').getcol('CHAN_FREQ')[0][0]>args.freqcut:
        os.system('rm -rf ' + ms)