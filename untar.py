import os
from glob import glob
import argparse

parser = argparse.ArgumentParser(description='')
parser.add_argument('--path', type=str, help='path')
args = parser.parse_args()

for filename in glob(args.path+"/*SB*.tar*"):
  outname=args.path+'/'+filename.split("%")[-1]
  os.rename(filename, outname)
  os.system('tar -xvf '+outname)
  os.system('rm -r '+outname)

  print(outname+' untarred.')