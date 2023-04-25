import os
import sys
from argparse import ArgumentParser

class Paths:
    """
    Read out paths to singularity and lofar_facet_selfcal and h5_merger
    """
    def __init__(self, singfile=None):
        """

        :param singfile: singularity file located in ~/singularity.info
        """
        if singfile is None:
            singfile = os.path.expanduser('~') + '/singularity.info'
            if not os.path.isfile(singfile):
                sys.exit(singfile + ' does not exist.'
                                    '\nPlease make a file with'
                                    '\n-----------'
                                    '\nBIND=<SINGULARITYBIND>'
                                    '\nSIMG=<SINGULARITY>'
                                    '\n-----------'
                                    '\nAnd name it ' + singfile)

        # parse singularity
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

        self.myhost = os.uname()[1]

        # verify host and give paths
        if 'surfsara.nl' in self.myhost:
            self.lofar_facet_selfcal = '/project/lofarvwf/Software/lofar_facet_selfcal/lofar_facet_selfcal.py'
            self.h5_merger = '/home/lofarvwf-jdejong/scripts/lofar_helpers/h5_merger.py'
        elif 'leidenuniv.nl' in self.myhost:
            self.lofar_facet_selfcal = '/net/rijn/data2/rvweeren/LoTSS_ClusterCAL/lofar_facet_selfcal.py'
            self.lofar_helpers = '/project/lofarvwf/Software/lofar_helpers/h5_merger.py'
        else:
            os.system('wget https://raw.githubusercontent.com/rvweeren/lofar_facet_selfcal/main/facetselfcal.py')
            os.system('wget https://raw.githubusercontent.com/jurjen93/lofar_helpers/master/h5_merger.py')
            self.lofar_facet_selfcal = os.getcwd()+'/lofar_facet_selfcal.py'
            self.lofar_helpers = os.getcwd()+'/h5_merger.py'


if __name__ == "__main__":

    parser = ArgumentParser(description='Return settings')
    parser.add_argument('--BIND', help='Singularity Bind', default="", action='store_true')
    parser.add_argument('--SIMG', help='Singularity Image', default="", action='store_true')
    parser.add_argument('--lofar_facet_selfcal', help='lofar_facet_selfcal path', default="", action='store_true')
    parser.add_argument('--lofar_helpers', help='lofar_helpers', default="", action='store_true')
    args = parser.parse_args()

    paths = Paths()
    if args.BIND:
        print(paths.BIND)
    elif args.SIMG:
        print(paths.SIMG)
    elif args.lofar_facet_selfcal:
        print(paths.lofar_facet_selfcal)
    elif args.lofar_helpers:
        print(paths.lofar_helpers)
    else:
        sys.exit('ERROR: NOTHING TO RETURN')




