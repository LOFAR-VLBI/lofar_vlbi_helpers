from multiprocessing import cpu_count
import tables
import sys
from subprocess import call
from argparse import ArgumentParser


def run(command):
    retval = call(command, shell=True)
    if retval != 0:
        print('FAILED to run ' + command + ': return value is ' + str(retval))
        raise Exception(command)
    return retval


def fulljonesparmdb(h5):
    H = tables.open_file(h5)
    try:
        phase = H.root.sol000.phase000.val[:]
        amplitude = H.root.sol000.amplitude000.val[:]
        if phase.shape[-1] == 4 and amplitude.shape[-1] == 4:
            fulljones = True
        else:
            fulljones = False
    except:
        fulljones = False
    H.close()
    return fulljones


def applycal(ms, inparmdblist, msincol='DATA', msoutcol=None, msout='.', dysco=True):
    # to allow both a list or a single file (string)
    if not isinstance(inparmdblist, list):
        inparmdblist = [inparmdblist]

    cmd = 'DPPP numthreads= ' + str(cpu_count()) + ' msin=' + ms + ' '
    if msoutcol:
        cmd += 'msout=' + msout + ' '
    cmd += 'msin.datacolumn=' + msincol + ' '
    cmd += 'msout.datacolumn=' + msoutcol + ' '
    if dysco:
        cmd += 'msout.storagemanager=dysco '
    count = 0
    for parmdb in inparmdblist:
        if fulljonesparmdb(parmdb):
            cmd += 'ac' + str(count) + '.parmdb=' + parmdb + ' '
            cmd += 'ac' + str(count) + '.type=applycal '
            cmd += 'ac' + str(count) + '.correction=fulljones '
            cmd += 'ac' + str(count) + '.soltab=[amplitude000,phase000] '
            count = count + 1
        else:
            H = tables.open_file(parmdb)
            try:
                phase = H.root.sol000.phase000.val[:]
                cmd += 'ac' + str(count) + '.parmdb=' + parmdb + ' '
                cmd += 'ac' + str(count) + '.type=applycal '
                cmd += 'ac' + str(count) + '.correction=phase000 '
                count = count + 1
            except:
                pass

            try:
                phase = H.root.sol000.tec000.val[:]
                cmd += 'ac' + str(count) + '.parmdb=' + parmdb + ' '
                cmd += 'ac' + str(count) + '.type=applycal '
                cmd += 'ac' + str(count) + '.correction=tec000 '
                count = count + 1
            except:
                pass

            try:
                phase = H.root.sol000.rotation000.val[:]
                cmd += 'ac' + str(count) + '.parmdb=' + parmdb + ' '
                cmd += 'ac' + str(count) + '.type=applycal '
                cmd += 'ac' + str(count) + '.correction=rotation000 '
                count = count + 1
            except:
                pass

            try:
                phase = H.root.sol000.amplitude000.val[:]
                cmd += 'ac' + str(count) + '.parmdb=' + parmdb + ' '
                cmd += 'ac' + str(count) + '.type=applycal '
                cmd += 'ac' + str(count) + '.correction=amplitude000 '
                count = count + 1
            except:
                pass

            H.close()

    if count < 1:
        print('Something went wrong, cannot build the applycal command. H5 file is valid?')
        sys.exit(1)
    # build the steps command
    cmd += 'steps=['
    for i in range(count):
        cmd += 'ac' + str(i)
        if i < count - 1:  # to avoid last comma in the steps list
            cmd += ','
    cmd += ']'

    print('DPPP applycal:', cmd)
    run(cmd)
    return


if __name__ == '__main__':
    parser = ArgumentParser(description='Applycal on MS with H5')
    parser.add_argument('--msin', type=str, help='input measurement set', required=True)
    parser.add_argument('--msout', type=str, default='.', help='output measurement set')
    parser.add_argument('--h5', type=str, help='h5 calibration', required=True)
    parser.add_argument('--colin', type=str, default='DATA', help='input column name')
    parser.add_argument('--colout', type=str, default=None, help='output column name')
    args = parser.parse_args()

    applycal(args.msin, inparmdblist=args.h5, msincol=args.colin, msoutcol=args.colout, msout=args.msout)
