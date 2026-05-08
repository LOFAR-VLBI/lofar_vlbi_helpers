import glob
import os
import numpy as np


def get_solutions_timerange(sols):
    t = np.load(sols)['BeamTimes']
    return np.min(t), np.max(t)


def fixsymlinks(ddsols):
    # Code from Tim Shimwell for fixing symbolic links for DDS3_
    # dds3smoothed = glob.glob('SOLSDIR/*/*killMS.DDS3_full_smoothed*npz')
    dds3 = glob.glob('SOLSDIR/*/killMS.' + ddsols + '.sols.npz')

    for i in range(0, len(dds3)):

        if 'slow' in ddsols:
            ext = 'merged'
        else:
            ext = 'smoothed'

        symsolname = dds3[i].split('killMS.' + ddsols + '.sols.npz')[0] + 'killMS.' + ddsols + '_' + ext + '.sols.npz'
        solname = dds3[i]

        start_time = float(glob.glob(ddsols + "*.npz")[0].split("_")[-2])

        if os.path.islink(symsolname):
            print('Symlink ' + symsolname + ' already exists, recreating')
            os.unlink(symsolname)
            os.symlink(os.path.relpath('../../%s_%s_%s.npz' % (ddsols, start_time, ext)), symsolname)
        else:
            print('Symlink ' + symsolname + ' does not yet exist, creating')
            os.symlink(os.path.relpath('../../%s_%s_%s.npz' % (ddsols, start_time, exit)), symsolname)

    return


fixsymlinks('DDS3_full')
fixsymlinks('DDS3_full_slow')
