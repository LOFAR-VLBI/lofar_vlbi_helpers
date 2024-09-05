import tables
import os
from glob import glob

for h5 in glob('/project/lofarvwf/Share/jdejong/output/ELAIS/ALL_L/imaging/DD_1.2/merged_L??????.h5'):

    newh5 = h5.replace('.h5', '_norm.h5')

    os.system(f'cp {h5} '+newh5)

    H = tables.open_file(newh5, 'r+')

    for i in range(len(H.root.sol000.amplitude000.dir[:])):
        meanamp = H.root.sol000.amplitude000.val[:, :, :, i, :].mean()
        print('Mean amp before: '+str(meanamp))
        H.root.sol000.amplitude000.val[:, :, :, i, :]/=meanamp

        print('Mean amp after: '+str(H.root.sol000.amplitude000.val[:, :, :, i, :].mean()))

    H.close()