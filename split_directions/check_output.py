import os
import pandas as pd
from glob import glob
from argparse import ArgumentParser
import casacore.tables as ct
import csv

def size_bytes(folder):
    """
    Return size in bytes round to 0 decimals
    :param folder: folder name
    :return: size in bytes
    """
    # assign size
    size = 0
    # get size
    for path, dirs, files in os.walk(folder):
        for f in files:
            fp = os.path.join(path, f)
            size += os.path.getsize(fp)
    return size

def size_mb(folder):
    """
    Return size in MB round to 0 decimals
    :param folder: folder name
    :return: size in MB
    """
    return int(round(size_bytes(folder)/1000000,0))

def size_gb(folder):
    """
    Return size in GB round to 0 decimals
    :param folder: folder name
    :return: size in GB
    """
    return int(round(size_bytes(folder)/1000000000,0))

def size_kb(folder):
    """
    Return size in kB round to 0 decimals
    :param folder: folder name
    :return: size in kB
    """
    return int(round(size_bytes(folder)/1000,0))

def corrupted_ms(ms):
    """
    Check if Measurement Set is corrupted by trying to open it

    :param ms: measurement set
    :return: boolean
    """
    try:
        t = ct.table(ms)
        t.close()
        return False
    except RuntimeError:
        return True

if __name__ == "__main__":

    parser = ArgumentParser(description='Check folder sizes')
    parser.add_argument('--folder', help='folder location', type=str, default=".")
    parser.add_argument('--size_lim', help='lowest allowed data size in MB', type=int, default=130)

    args = parser.parse_args()

    # all measurement sets
    all_ms = [f for f in glob(args.folder+'/'+'*.ms') if 'P' in f and 'L' in f and 'MHz' in f and 'sub6asec' not in f]
    # all observations (L-numbers)
    all_obs = list(set([f.split('/')[-1].split('_')[0] for f in all_ms]))
    # all frequencies
    all_freqs = list(set([f.split('/')[-1].split('_')[1] for f in all_ms if 'MHz' in f]))
    # all directions
    all_dirs = list(set([f.split('/')[-1].split('_')[2].split('.')[0] for f in all_ms if 'P' in f]))

    with open('msfiles.csv', 'w', newline='') as file:
        writer = csv.writer(file)

        writer.writerow(["file", "corrupted", "size", "direction"])

        for obs in all_obs:
            obs_ok = True
            for dir in all_dirs:
                for ms_p in glob(args.folder+'/'+obs+'_*_'+dir+'.ms'):
                    try:
                        ms_size = size_mb(ms_p)
                        if corrupted_ms(ms_p):
                            obs_ok = False
                            writer.writerow([ms_p.split('/')[-1], True, ms_size, dir])
                            print(ms_p.split('/')[-1] + ' --> Corrupted')

                        elif ms_size<args.size_lim:
                            obs_ok = False
                            writer.writerow([ms_p.split('/')[-1], True, ms_size, dir])
                            print(ms_p.split('/')[-1] + ' --> Too small')

                        else:
                            writer.writerow([ms_p.split('/')[-1], False, ms_size, dir])
                    except:
                        print(ms_p.split('/')[-1]+' --> does not exist')

    # make folders
    os.system('mkdir -p '+args.folder+'/sub_parsets')
    os.system('mkdir -p '+args.folder+'/concat_parsets')

    # remove corrupted data
    df = pd.read_csv('msfiles.csv')
    for ms in list(df[df.corrupted].file):
        os.system('rm -rf '+args.folder+'/'+ms)
        print(ms+' removed')

    # move finished parsets
    for parset in [args.folder+'/'+f.replace('.ms', '.parset') for f in df[~df['corrupted']].file]:
        os.system("mv "+args.folder+"/"+parset+" "+args.folder+"/"+"sub_parsets")
