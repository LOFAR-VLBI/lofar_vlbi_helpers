from glob import glob
import os
import tables
import pandas as pd


def make_utf8(inp):
    """
    Convert input to utf8 instead of bytes

    :param inp: string input
    """

    try:
        inp = inp.decode('utf8')
        return inp
    except (UnicodeDecodeError, AttributeError):
        return inp

if __name__ == "__main__":

    selfcalperformance = pd.read_csv('selfcal_performance.csv').set_index('source')

    selected = ['P16883',
                'P17010',
                'P17565',
                'P19951',
                'P20075',
                'P22459',
                'P23167',
                'P23872',
                'P24227',
                'P27648',
                'P31553',
                'P31933',
                'P34557',
                'P35307',
                'P37145',
                'P40952',
                'P41028',
                'P44832',
                'P46921',
                'P48367',
                'P50716',
                'P50735',
                'P50892',
                'P50980',
                'P51372',
                'P52238',
                'P53426',
                'P54920',
                'P57108',
                'P58902']

    infield = 'P50980'
    infidx = selected.index(infield)

    nights = ['L769393', 'L686962', 'L816272', 'L798074']

    for n in nights:
        print("########\n"+n+"\n########\n")
        solutionfiles = []
        for s in selected:
            best_cycle = selfcalperformance.loc[s].best_cycle
            besth5 = sorted(glob(s+f'/merged_addCS_selfcalcyle0*{n}_P?????.ms.copy.phaseup.h5'))[int(best_cycle)]
            print(besth5)
            solutionfiles.append(besth5)
        infiles = ' '.join(solutionfiles)
        outfile = 'merged_' + n + '.h5'
        os.system(
            'python /project/lofarvwf/Software/h5_merger.py '
            '-in ' + infiles + ' -out ' + outfile + ' --propagate_flags --no_stationflag_check')
        H = tables.open_file(outfile, 'r+')
        dirind = make_utf8(H.root.sol000.phase000.val.attrs['AXES']).split(',').index('dir')
        if dirind == 0:
            H.root.sol000.phase000.val[infidx, ...] = 0
            H.root.sol000.amplitude000.val[infidx, ...] = 1
        if dirind == 1:
            H.root.sol000.phase000.val[:, infidx, ...] = 0
            H.root.sol000.amplitude000.val[:, infidx, ...] = 1
        if dirind == 2:
            H.root.sol000.phase000.val[:, :, infidx, ...] = 0
            H.root.sol000.amplitude000.val[:, :, infidx, ...] = 1
        if dirind == 3:
            H.root.sol000.phase000.val[:, :, :, infidx, ...] = 0
            H.root.sol000.amplitude000.val[:, :, :, infidx, ...] = 1
        if dirind == 4:
            H.root.sol000.phase000.val[:, :, :, :, infidx, ...] = 0
            H.root.sol000.amplitude000.val[:, :, :, :, infidx, ...] = 1
