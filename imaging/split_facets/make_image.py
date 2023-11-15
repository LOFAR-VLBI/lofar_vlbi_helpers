from pandas import read_csv
from argparse import ArgumentParser
import casacore.tables as ct
import os
import sys
import random

def get_largest_divider(inp, max=1000):
    """
    Get largest divider

    :param inp: input number
    :param max: max divider

    :return: largest divider from inp bound by max
    """
    for r in range(max+1)[::-1]:
        if inp % r == 0:
            return r

def make_wsclean_cmd(imsize, scale, name, taper, tmpdir, avg):
    """
    Make wsclean commando

    :param imsize: image size
    :param scale: scale in arcsec
    :param name: name prefix
    :param ms: list with measurement sets
    :param tmpdir: use scratch
    :param avg: averaging factor

    :return:
    """

    os.system('cp ~/parse_settings.py . && sleep 5')

    from parse_settings import ScriptPaths
    paths = ScriptPaths()
    simg = paths.SIMG


    cmd = \
f"""#!/bin/bash
#SBATCH -c 31
#SBATCH --mail-type=FAIL,END
#SBATCH --mail-user=jurjendejong@strw.leidenuniv.nl
#SBATCH --job-name={name}
#SBATCH --constraint=rome
"""
    if avg <= 3:
        cmd += """#SBATCH -p infinite
"""
    cmd+=\
"""

"""

    if tmpdir:
        if avg > 3 or pixelscale!=0.1:
            cmd += \
f"""OUTPUT=$PWD
RUNDIR=$TMPDIR/DIR{str(random.getrandbits(20))}
mkdir -p $RUNDIR
cp {simg} $RUNDIR
cp -r *sub*.ms $RUNDIR
cd $RUNDIR

"""
        else:
            cmd += \
f"""OUTPUT=$PWD
RUNDIR=$TMPDIR/DIR{str(random.getrandbits(20))}
mkdir -p $RUNDIR
cp {simg} $RUNDIR
cd $RUNDIR

"""
    cmd+= \
f"""
singularity exec -B {os.getcwd()},$PWD {simg.split('/')[-1]} wsclean \\
-gridder wgridder \\
-no-update-model-required \\
-minuv-l 80.0 \\
-size {imsize} {imsize} \\
-weighting-rank-filter 3 \\
-reorder \\
-weight briggs -1.5 \\
-parallel-reordering 4 \\
-mgain 0.75 \\
-data-column DATA \\
-auto-mask 2.5 \\
-auto-threshold 1.0 \\
-pol i \\
-name {name} \\
-scale {scale}arcsec \\
-niter 500000 \\
-log-time \\
-multiscale-scale-bias 0.6 \\
-parallel-deconvolution 2600 \\
-multiscale \\
-multiscale-max-scales 9 \\
-nmiter 9 \\
-parallel-gridding 4 \\
-channels-out 6 \\
-join-channels \\
-fit-spectral-pol 3 \\
-local-rms -local-rms-window 50 \\"""

    if taper is not None:
        cmd += f'\n-taper-gaussian {taper} \\'
    if avg>3 or pixelscale!=0.1:
        cmd += f"\n*.ms\n"
    else:
        cmd += f"\n{os.getcwd()}/{name}/imaging/*.ms"

    if tmpdir:
        cmd+= \
"""

cp *.fits $OUTPUT
"""

    f = open(f"wsclean_facet{args.facet}.cmd", "w")
    f.write(cmd)
    f.close()

    return cmd


if __name__=='__main__':
    parser = ArgumentParser(description='make imaging command')
    parser.add_argument('--resolution', help='resolution in arcsecond', required=True, type=float)
    parser.add_argument('--facet', help='facet_number (polygon number)', required=True, type=int)
    parser.add_argument('--facet_info', help='polygon_info.csv', required=True)
    # parser.add_argument('--ms', help='measurement set(s)', required=True,  nargs='+')
    parser.add_argument('--tmpdir', action='store_true', help='use tmpdir',
                        default=False)
    args = parser.parse_args()

    if args.resolution==0.3:
        taper = '0.3asec'
        pixelscale = 0.1 #arcsec
    elif args.resolution==1.2:
        taper = '1.2asec'
        pixelscale = 0.4
    elif args.resolution==0.6:
        taper = '0.6asec'
        pixelscale = 0.2
    else:
        sys.exit('ERROR: only use resolution 0.3 or 1.2')

    fullpixsize = int(2.5*3600/pixelscale)

    # polygon information
    polygon_info = read_csv(args.facet_info).set_index('idx')
    facet = polygon_info.loc[args.facet]
    facet_avg = facet.avg

    # number of channels
    # t = ct.table(args.ms[0]+"::SPECTRAL_WINDOW")
    # channum = len(t.getcol("CHAN_FREQ")[0])
    # t.close()

    # factor to divide full size by
    # divide_size = get_largest_divider(channum, facet_avg)
    # imsize = int((fullpixsize//divide_size)*1.15)

    imsize = int((fullpixsize//(facet_avg-1))*1.25)

    make_wsclean_cmd(imsize, pixelscale, 'facet_'+str(args.facet), taper, args.tmpdir, facet_avg)
