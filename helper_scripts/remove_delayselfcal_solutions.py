import tables
import casacore.tables as ct
import numpy as np
import os

currentdir = os.getcwd()
observation = [p for p in currentdir.split('/') if len(p)==7 and p[0]=='L'][0]
H = tables.open_file(f"/project/lofarvwf/Share/jdejong/output/ELAIS/{observation}/ddcal/selfcals/master_merged.h5", 'r+')
t = ct.table(f'/project/lofarvwf/Share/jdejong/output/ELAIS/{observation}/delayselfcal/{observation}_120_168MHz_averaged.ms::FIELD')

phasedir = np.ndarray.flatten(t.getcol("PHASE_DIR"))
dirs = H.root.sol000.source[:]['dir']
dirindex = H.root.sol000.phase000.val.attrs["AXES"].decode('utf-8').split(',').index('dir')

for n, d in enumerate(dirs):
    distance = np.linalg.norm(d-phasedir)
    if distance<1e-5:
        delay_dir = n
        if dirindex==3:
            H.root.sol000.amplitude000.val[:, :, :, delay_dir, :] = 1.
            H.root.sol000.phase000.val[:, :, :, delay_dir, :] = 0.

H.close()
t.close()