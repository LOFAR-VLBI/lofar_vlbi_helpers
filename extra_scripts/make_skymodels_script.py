from astropy.io import fits
from glob import glob

cmd = ['#!/bin/bash', '#SBATCH -c 10', 'mkdir skymodels']

sing = '/project/lofarvwf/Software/singularity/lofar_sksp_v4.2.3_znver2_znver2_aocl4_debug_manualfftwtest.sif'
bind = '/project,/project/lofarvwf/Software,/project/lofarvwf/Share,/project/lofarvwf/Public,/home/lofarvwf-jdejong'

for P in glob("P?????"):
    print(P)
    try:
        cmd+=['cd '+P]
        f = fits.open(P+"/selfcal_011-MFS-image.fits")
        wsclean_cmd = ' '.join(''.join(str(f[0].header["HISTORY"]).split('\n')).split()[0:-4])+' -save-source-list '
        MS = glob(P+"/L??????_"+P+".ms.copy.phaseup")
        for M in MS:
            print(M)
            cmd+=['singularity exec -B '+bind+' '+sing+' '+wsclean_cmd + M.split("/")[-1]]
            cmd+=['mv selfcal_011-sources.txt ../skymodels/'+P+'_'+M.split("/")[-1].split("_")[0]+'-sources.txt']
        cmd+=['cd ../']
    except:
        print('WARNING: '+P+' not added')

with open('makeskymodels.cmd', 'w') as f:
    f.write('\n'.join(cmd))
