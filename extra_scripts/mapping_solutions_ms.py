from glob import glob
from argparse import ArgumentParser
import os

def isin(inp, lst):
    """
    Verify if element from list is in the input
    :param inp: input name
    :param lst: list of elements
    :return:
    """
    for el in lst:
        if el in inp:
            return True
    return False

if __name__ == "__main__":
    parser = ArgumentParser(description='Make text files mapped for h5 and ms')
    parser.add_argument('nights', help='Nights to map (separated by commas --> example: L76312,L98123,...', type=str)
    args = parser.parse_args()

    lnum = args.nights.replace(' ','').split(',')

    h5s = sorted([os.path.abspath(h5) for h5 in glob('../merged*.h5') if isin(h5, lnum)])
    mss = sorted([os.path.abspath(ms) for ms in glob('../avg*.ms') if isin(ms, lnum)])

    os.system('[ -e h5s.txt ] && rm h5s.txt && [ -e mss.txt ] && rm mss.txt')
    f = open("h5list.txt", "a+")
    g = open("mslist.txt", "a+")
    for l in lnum:
        for ms in mss:
            if l in ms:
                for h5 in h5s:
                    if l in h5:
                        f.write(h5+'\n')
                        g.write(ms+'\n')

    f.close()
    g.close()
