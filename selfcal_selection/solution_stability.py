import re
import tables
from glob import glob
from scipy.stats import circstd, linregress
import numpy as np
import matplotlib.pyplot as plt
from argparse import ArgumentParser

def get_cycle_num(fitsfile):
    """
    Parse cycle number

    :param fitsfile: fits file name
    """
    return int(float(re.findall("\d{3}", fitsfile.split('/')[-1])[0]))

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

def get_solution_scores(h5_1, h5_2):
    """
    Get solution evolution

    :param h5_1: solution file 1
    :param h5_2: solution file 2
    :return: circular std phase difference score, std amp difference score
    """

    # PHASE VALUES
    H = tables.open_file(h5_1)
    axes = make_utf8(H.root.sol000.phase000.val.attrs['AXES']).split(',')
    vals1 = H.root.sol000.phase000.val[:]
    weights1 = H.root.sol000.phase000.weight[:]

    F = tables.open_file(h5_2)
    vals2 = F.root.sol000.phase000.val[:]
    weights2 = F.root.sol000.phase000.weight[:]

    if remoteonly and not internationalonly:
        stations = [i for i, station in enumerate(H.root.sol000.antenna[:]['name']) if (b'RS' in station)]
        vals1 = np.take(vals1, stations, axis=axes.index('ant'))
        weights1 = np.take(weights1, stations, axis=axes.index('ant'))
        vals2 = np.take(vals2, stations, axis=axes.index('ant'))
        weights2 = np.take(weights2, stations, axis=axes.index('ant'))

    elif internationalonly and not remoteonly:
        stations = [i for i, station in enumerate(H.root.sol000.antenna[:]['name']) if not (b'RS' in station)]
        vals1 = np.take(vals1, stations, axis=axes.index('ant'))
        weights1 = np.take(weights1, stations, axis=axes.index('ant'))
        vals2 = np.take(vals2, stations, axis=axes.index('ant'))
        weights2 = np.take(weights2, stations, axis=axes.index('ant'))

    # take circular std from difference of previous and current selfcal cycle
    phasescore = circstd(np.nan_to_num(vals1) * weights1 - np.nan_to_num(vals2) * weights2)

    # AMP VALUES
    vals1 = H.root.sol000.amplitude000.val[:]
    vals2 = F.root.sol000.amplitude000.val[:]

    if remoteonly and not internationalonly:
        vals1 = np.take(vals1, stations, axis=axes.index('ant'))
        vals2 = np.take(vals2, stations, axis=axes.index('ant'))

    elif internationalonly and not remoteonly:
        vals1 = np.take(vals1, stations, axis=axes.index('ant'))
        vals2 = np.take(vals2, stations, axis=axes.index('ant'))

    # take std from difference of previous and current selfcal cycle
    ampscore = np.std(np.nan_to_num(vals1) * weights1 - np.nan_to_num(vals2) * weights2)

    H.close()
    F.close()

    return phasescore, ampscore


def linreg_slope(values):
    """
    Fit linear regression and return slope
    :param values: Values
    :return:
    """
    return linregress(list(range(len(values))), values).slope

def make_figure(vals1, vals2, plotname):
    """
    Make figure

    :param phase_scores:
    :param amp_scores:
    :param plotname:
    :return:
    """
    fig, ax1 = plt.subplots()

    color = 'tab:red'
    ax1.set_xlabel('cycle')
    ax1.set_ylabel('Phase stability', color=color)
    ax1.plot([i + 1 for i in range(len(vals1))], vals1, color=color)
    ax1.tick_params(axis='y', labelcolor=color)
    # ax1.set_ylim(0, np.pi/2)
    ax1.set_xlim(1, 11)

    ax2 = ax1.twinx()

    color = 'tab:blue'
    ax2.set_ylabel('Amplitude stability', color=color)
    ax2.plot([i + 1 for i in range(len(vals2))], vals2, color=color)
    ax2.tick_params(axis='y', labelcolor=color)
    # ax2.set_ylim(0, 2)
    ax2.set_xlim(1, 11)

    ax1.grid(False)
    ax1.grid('off')
    ax1.grid(None)
    ax2.grid(False)
    ax2.grid('off')
    ax2.grid(None)
    fig.tight_layout()

    plt.savefig(plotname, dpi=300)


if __name__ == '__main__':

    parser = ArgumentParser(description='Determine solution stability')
    parser.add_argument('--remote_only', action='store_true', help='Only remote stations are considered', default=None)
    parser.add_argument('--international_only', action='store_true', help='Only international stations are considered', default=None)
    args = parser.parse_args()

    regex = "merged_selfcalcyle\d{3}\_"

    remoteonly = args.remote_only
    internationalonly = args.international_only

    #select all h5s
    h5s = glob("merged_selfcalcyle*.h5")

    assert len(h5s)!=0, "No h5 files found"

    #select all sources
    sources = set([re.sub(regex, '',h).replace('.ms.copy.phaseup.h5','') for h in h5s])

    #loop over sources
    for k, source in enumerate(sources):
        print(source)
        sub_h5s = sorted([h5 for h5 in h5s if source in h5])
        phase_scores = []
        amp_scores = []
        for m, sub_h5 in enumerate(sub_h5s):
            number = get_cycle_num(sub_h5)
            print(sub_h5, sub_h5s[m-1])
            if number>0:
                phasescore, ampscore = get_solution_scores(sub_h5, sub_h5s[m - 1])
                phase_scores.append(phasescore)
                amp_scores.append(ampscore)
        if k==0:
            total_phase_scores = [phase_scores]
            total_amp_scores = [amp_scores]
        else:
            total_phase_scores = np.append(total_phase_scores, [phase_scores], axis=0)
            total_amp_scores = np.append(total_amp_scores, [amp_scores], axis=0)

    # PLOT
    if remoteonly:
        plotname = f'selfcal_stability_remote_{source.split("_")[-1]}.png'
    elif internationalonly:
        plotname = f'selfcal_stability_international_{source.split("_")[-1]}.png'
    else:
        plotname = f'selfcal_stability_{source.split("_")[-1]}.png'
    finalphase = np.mean(total_phase_scores, axis=0)
    finalamp = np.mean(total_amp_scores, axis=0)
    print(linreg_slope(finalphase), linreg_slope(finalamp[4:]))
    make_figure(finalphase, finalamp, plotname)
