import casacore.tables as ct
from glob import glob
from sys import exit
import numpy as np
from argparse import ArgumentParser


if __name__ == "__main__":
    parser = ArgumentParser(description='Compare phase centers')
    parser.add_argument('--ms', help='List of ms', type=str, nargs='+', required=True)
    args = parser.parse_args()

    if args.ms is None:
        mslist = glob("*.ms")
    else:
        mslist = args.ms

    t = ct.table(mslist[0] + "::FIELD")
    ref_phasecenter = t.getcol("PHASE_DIR")
    t.close()

    for ms in mslist:
        print(ms)
        t = ct.table(ms + "::FIELD")
        if np.sum(t.getcol("PHASE_DIR")-ref_phasecenter)!=0:
            t.close()
            exit(ms+'\nand\n'+mslist[0]+'\ndo not have the same phase center')
        t.close()