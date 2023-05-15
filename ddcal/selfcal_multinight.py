from glob import glob
import os

directions = set([f.split("_")[1].split('.')[0] for f in glob('L??????_P*.ms')])

for d in directions:
    print(d)
    tasks = ['mkdir -p '+d, 'mv L??????_'+d+'.ms '+d, 'cd '+d, 'sbatch ../selfcal_multi_night.sh '+d, 'cd ../']
    print(' && '.join(tasks))
    os.system(' && '.join(tasks))