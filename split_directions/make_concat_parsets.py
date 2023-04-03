#!/usr/bin/env python

from glob import glob
import os

all_ms = [f for f in glob('*.ms') if 'P' in f and 'L' in f and 'MHz' in f and 'sub6asec' not in f]

all_obs = list(set([f.split('_')[0] for f in all_ms]))
all_freqs = list(set([f.split('_')[1] for f in all_ms if 'MHz' in f]))
all_dirs = list(set([f.split('_')[2].split('.')[0] for f in all_ms if 'P' in f]))

for observation in all_obs:
    for dir in all_dirs:
        mslist = glob(observation + '*' + dir + '.ms')
        mschain = ' '.join(mslist)
        txt_name = observation + '_' + dir + '.txt'
        os.system(f'python /home/lofarvwf-jdejong/scripts/lofar_vlbi_helpers/extra_scripts/check_missing_freqs_in_ms.py --ms {mschain} --make_dummies --output_name {txt_name}')
        with open(txt_name) as f:
            lines = f.readlines()
        parset = 'msin=' + '['+', '.join(lines).replace('\n', '')+']'
        parset += 'msout=' + observation + '_' + dir + '.ms'
        parset += '\nmsin.datacolumn=DATA' \
                  '\nmsin.missingdata=True' \
                  '\nmsin.orderms=False' \
                  '\nmsout.storagemanager=dysco' \
                  '\nmsout.writefullresflag=False' \
                  '\nsteps=[]'
        with open(observation + '_' + dir + '.parset', 'w') as f:
            f.write(parset)
