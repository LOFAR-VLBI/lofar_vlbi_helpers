#!/usr/bin/env python

from glob import glob
import os

MS = '*.ms'

all_ms = [f for f in glob(MS) if 'L' in f and 'MHz' in f and 'sub6asec' not in f]

all_obs = ['L769393', 'L686962', 'L816272', 'L798074']
all_freqs = list(set([f.split('_')[-1].split('.')[0]  for f in all_ms if 'MHz' in f]))

for observation in all_obs:
    try:
        mslist = glob('*'+observation+MS.split('/')[-1])
        mschain = ' '.join(mslist)
        txt_name = observation + '_concat.txt'
        os.system(f'python /home/lofarvwf-jdejong/scripts/lofar_vlbi_helpers/extra_scripts/check_missing_freqs_in_ms.py --ms {mschain} --make_dummies --output_name {txt_name}')
        with open(txt_name) as f:
            lines = f.readlines()
        parset = 'msin=' + '['+', '.join(lines).replace('\n', '')+']\n'
        parset += 'msout=' + observation + '_concat.ms'
        parset += '\nmsin.datacolumn=DATA' \
                  '\nmsin.missingdata=True' \
                  '\nmsin.orderms=False' \
                  '\nmsout.storagemanager=dysco' \
                  '\nmsout.writefullresflag=False' \
                  '\nsteps=[]'
        with open(observation + '_concat.parset', 'w') as f:
            f.write(parset)
    except FileNotFoundError:
        with open('failed_concat.txt', 'a+') as f:
            f.write(observation+'_concat\n')
