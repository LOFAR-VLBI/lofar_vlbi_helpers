import lsmtool
from glob import glob

skymodels = glob('*.skymodel')

for n, skymodel in enumerate(skymodels):
    if n==0:
        s = lsmtool.load(skymodel)
    else:
        s.concatenate(LSM2=skymodel)

s.write('full.skymodel')