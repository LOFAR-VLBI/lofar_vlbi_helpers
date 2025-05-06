import glob
import os
import numpy as np


def get_solutions_timerange(sols):
    t = np.load(sols)['BeamTimes']
    return np.min(t), np.max(t)


def fixsymlinks(ddsols):
    # Code from Tim for fixing symbolic links for DDS3_
    # dds3smoothed = glob.glob('SOLSDIR/*/*killMS.DDS3_full_smoothed*npz')
    dds3 = glob.glob('SOLSDIR/*/killMS.' + ddsols + '.sols.npz')

    for i in range(0, len(dds3)):

        if 'slow' in ddsols:
            ext = 'merged'
        else:
            ext = 'smoothed'

        symsolname = dds3[i].split('killMS.' + ddsols + '.sols.npz')[0] + 'killMS.' + ddsols + '_' + ext + '.sols.npz'
        solname = dds3[i]

        # start_time,t1 = get_solutions_timerange(solname)
        # Rounding different on different computers which is a pain.
        # print(start_time, t1)
        # print(glob.glob(ddsols+"*.npz")[0].split("_"))
        start_time = float(glob.glob(ddsols + "*.npz")[0].split("_")[-2])
        # start_time = glob.glob('%s_%s*_smoothed.npz'%(ddsols,int(start_time)))[0].split('_')[2]

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
