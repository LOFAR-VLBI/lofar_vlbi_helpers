#!/usr/bin/env python

from glob import glob

all_ms = [f for f in glob('*.ms') if 'P' in f and 'L' in f and 'MHz' in f and 'sub6asec' not in f]

all_obs = list(set([f.split('_')[0] for f in all_ms]))
all_freqs = list(set([f.split('_')[1] for f in all_ms if 'MHz' in f]))
all_dirs = list(set([f.split('_')[2].split('.')[0] for f in all_ms if 'P' in f]))

for observation in all_obs:
    for dir in all_dirs:
        parset = 'msin=' + observation + '*' + dir + '.ms'
        parset += '\nmsout=' + observation + '_' + dir + '.ms'
        parset += '\nmsin.datacolumn=DATA\nmsout.storagemanager=dysco\nmsout.writefullresflag=False\nsteps=[]'
        with open(observation + '_' + dir + '.parset', 'w') as f:
            f.write(parset)
