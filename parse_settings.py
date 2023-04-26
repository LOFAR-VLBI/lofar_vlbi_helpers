#!/usr/bin/python

__author__ = "Jurjen de Jong (jurjendejong@strw.leidenuniv.nl)"
__all__ = ['ScriptPaths']

import os
import sys
from argparse import ArgumentParser
import subprocess
if sys.version_info.major == 2:
    from urllib2 import urlopen
else:
    from urllib.request import urlopen
from glob import glob

home = os.path.expanduser('~')

#LEIDEN HAS ONLY INTEL NODES
leiden_bind = "/tmp,/dev/shm,/net/tussenrijn,/net/achterrijn,/net/krommerijn,/net/nieuwerijn,/net/rijn,/net/rijn1," \
              "/net/rijn2,/net/rijn3,/net/rijn4,/net/rijn5,/net/rijn6,/net/rijn7,/net/rijn8,/net/rijn9,/net/rijn10,/net/rijn11,"+home
leiden_simg = "/net/achterrijn/data1/sweijen/software/containers/lofar_sksp_v4.0.2_x86-64_cascadelake_cascadelake_avx512_mkl_cuda_ddf.sif"
leiden_h5_merger = '/net/tussenrijn/data2/jurjendejong/lofar_helpers/h5_merger.py'
leiden_facet_selfcal = '/net/rijn/data2/rvweeren/LoTSS_ClusterCAL/facetselfcal.py'

#SURFSARA HAS INTEL AND AMD NODES
surf_bind = "/project,/project/lofarvwf/Software,/project/lofarvwf/Share,/project/lofarvwf/Public,"+home
surf_simg_amd = "/project/lofarvwf/Software/singularity/lofar_sksp_v4.1.0_znver2_znver2_noavx512_aocl3_cuda_ddf.sif"
surf_simg_intel = "/project/lofarvwf/Software/singularity/lofar_sksp_v4.0.2_x86-64_cascadelake_cascadelake_avx512_mkl_cuda_ddf.sif"
surf_h5_merger = '/project/lofarvwf/Software/lofar_helpers/h5_merger.py'
surf_facet_selfcal = '/project/lofarvwf/Software/lofar_facet_selfcal/facetselfcal.py'

#SCRIPT PATHS
h5_merger_path = "https://raw.githubusercontent.com/rvweeren/lofar_facet_selfcal/main/facetselfcal.py"
facet_selfcal_path = "https://raw.githubusercontent.com/jurjen93/lofar_helpers/master/h5_merger.py"

class ScriptPaths:
    """
    Read out paths to singularity and facet_selfcal and h5_merger
    """
    def __init__(self, singfile=None):
        """

        :param singfile: singularity file located in ~/singularity.info
        """

        self.myhost = os.uname()[1]

        if singfile is None:
            singfile = home + '/singularity.info'

        if not os.path.isfile(singfile):
            # check system and extract paths from there
            if 'surfsara.nl' in self.myhost:
                self.BIND= surf_bind
                if 'intel' in (subprocess.check_output("lscpu", shell=True).strip()).decode().lower():
                    self.SIMG= surf_simg_intel
                else:
                    self.SIMG = surf_simg_amd

            elif 'leidenuniv.nl' in self.myhost:
                self.BIND = leiden_bind
                self.SIMG = leiden_simg

            else:
                sys.exit(singfile + ' does not exist.'
                                    '\nPlease make a file with'
                                    '\n-----------'
                                    '\nBIND=<SINGULARITYBIND>'
                                    '\nSIMG=<SINGULARITY>'
                                    '\n-----------'
                                    '\nAnd name it ' + singfile)
        else:
            # parse singularity from ~/singularity.info
            with open(singfile) as f:
                lines = f.readlines()
                if 'BIND' in lines[0] and args.BIND:
                    self.BIND = lines[0].replace('\n', '').replace('BIND=', '')
                elif args.BIND:
                    sys.exit('BIND=<SINGULARITYBIND> is missing in ' + singfile)
                elif 'SIMG' in lines[1] and args.SIMG:
                    self.SIMG = lines[1].replace('\n', '').replace('SIMG=', '')
                elif args.SIMG:
                    sys.exit('SIMG=<SINGULARITY> is missing in ' + singfile)

        # verify host and give paths
        if 'surfsara.nl' in self.myhost:
            self.facet_selfcal = surf_facet_selfcal
            self.h5_merger = surf_h5_merger
        elif 'leidenuniv.nl' in self.myhost:
            self.facet_selfcal = leiden_facet_selfcal
            self.h5_merger = leiden_h5_merger
        else:
            if self.internet_connection:
                os.system('wget '+h5_merger_path)
                os.system('wget '+facet_selfcal_path)

            elif 'h5_merger.py' in [py.split('/')[-1] for py in glob('*.py')] and 'facetselfcal.py' in [py.split('/')[-1] for py in glob('*.py')]:
                self.facet_selfcal = os.getcwd()+'/facetselfcal.py'
                self.h5_merger = os.getcwd()+'/h5_merger.py'
            else:
                print('No internet connection and cannot find h5_merger.py or facetselfcal.py')

    @property
    def internet_connection(self):
        try:
            urlopen(h5_merger_path, timeout=1)
            return True
        except:
            return False



if __name__ == "__main__":

    parser = ArgumentParser(description='Return settings')
    parser.add_argument('--BIND', help='Singularity Bind', default="", action='store_true')
    parser.add_argument('--SIMG', help='Singularity Image', default="", action='store_true')
    parser.add_argument('--facet_selfcal', help='facetselfcal.py in facet_selfcal', default="", action='store_true')
    parser.add_argument('--h5_merger', help='h5_merger.py in lofar_helpers', default="", action='store_true')
    args = parser.parse_args()

    paths = ScriptPaths()
    if args.BIND:
        print(paths.BIND)
    if args.SIMG:
        if 'surfsara.nl' in paths.myhost and \
                'intel' in (subprocess.check_output("lscpu", shell=True).strip()).decode().lower() and \
                'cascadelake' not in args.SIMG:
            print(surf_simg_intel)
        else:
            print(paths.SIMG)
    if args.facet_selfcal:
        print(paths.facet_selfcal)
    if args.h5_merger:
        print(paths.h5_merger)


"""
USAGE:

################################

In Python:

from parse_settings import ScriptPaths

paths = ScriptPaths()

#Singularity Bind
paths.BIND

#Singularity image
paths.SIMG

#facetselfcal.py
paths.lofar_facet_selfcal

#h5_merger.py
paths.h5_merger

################################

On commandline or in bash:

# get singularity bind
python parse_settings.py --BIND

# get singularity image
python parse_settings.py --SIMG

# get facetselfcal
python parse_settings.py --facet_selfcal

# get h5_merger
python parse_settings.py --h5_merger

################################

"""