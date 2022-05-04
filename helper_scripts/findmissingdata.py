#!/usr/bin/env python3
# -*- coding: utf-8 -*-

#Imports
from glob import glob
import argparse

parser = argparse.ArgumentParser(description='')
parser.add_argument('--path', type=str, help='path')
args = parser.parse_args()

data_dict = {}

for f in glob(args.path+"/*.tar"):
    ID_end = f.find("_SB")
    ID_start = ID_end - 7
    SB_start = ID_end+3
    SB_end = SB_start+3
    
    ID = f[ID_start:ID_end]
    SB = f[SB_start:SB_end]
    
    if ID not in data_dict.keys():
        data_dict[ID] = [int(SB)]
    else:
        data_dict[ID].append(int(SB))

for key in data_dict.keys():
    missing_SBs = []
    data_dict[key].sort()
    first_SB = data_dict[key][0]
    last_SB = data_dict[key][-1]
    all_SBs = range(first_SB, last_SB+1)
    for SB in all_SBs:
        if SB not in data_dict[key]:
            missing_SBs.append(SB)
    print("For data set {}, you are missing the following SBs between SB{:03d} and SB{:03d}:".format(key, first_SB, last_SB))
    print("{}\n".format(str(missing_SBs)[1:-1]))