import casacore.tables as ct
from glob import glob
import argparse
import os
import subprocess

def du(path):
    """Return folder size in GB"""
    size = subprocess.check_output(['du','-sh', path]).split()[0].decode('utf-8')
    return float(''.join([n for n in size if n.isdigit()]))

def get_size(start_path = '.'):
    """Return folder size in B (different than du(path)?)"""
    total_size = 0
    for dirpath, dirnames, filenames in os.walk(start_path):
        for f in filenames:
            fp = os.path.join(dirpath, f)
            # skip if it is symbolic link
            if not os.path.islink(fp):
                total_size += os.path.getsize(fp)
    return total_size

parser = argparse.ArgumentParser(description='')
parser.add_argument('--path', type=str, help='path', default='.')
args = parser.parse_args()

files = glob(args.path+'/sub6asec*.ms')

print('There are '+str(len(files))+' files:\n'+'\n'.join(files))
MS_sizes = []
for n, f in enumerate(files):
    try:
        t = ct.table(f)
        assert 'DATA' in t.colnames()
        t.close()
    except:
        print('CORRUPTED:\n'+f)
    if n>0: # validate if file sizes are the same as previous one
        if du(files[n-1])!=du(f):
            print('ERROR:\n'+files[n-1]+' and '+f+' do not have the same file size.')
