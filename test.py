import astropy.units as u
import numpy as np
import matplotlib.pyplot as plt
from scipy import signal
from scipy.optimize import curve_fit


def hdfig(subplots_def=None, scale=0.5):
    '''
    A little tool for making figures later .
    '''
    fig = plt.figure(figsize=(8, 4.5), dpi=scale * 1920 / 8)
    if subplots_def is None:
        return fig
    else:
        return fig, fig.subplots(*subplots_def)


def read_file(file1, file2, offset):
    step = 2
    length = 60_000_000
    start = 10_000_000
    stop = start + length
    print(f" Reading in {((stop - start) / step / sample_clock).to(u.s)} of data ")
    count = 80_000_000
    data1 = np.fromfile(file1, dtype=np.int16, count=count)
    data2 = np.fromfile(file2, dtype=np.int16, count=count)
    d1 = data1[start + offset: stop + offset: step] * 1.0 \
         + data1[start + 1 + offset: stop + offset: step] * 1.0j
    d2 = data2[start - offset: stop - offset: step] * 1.0 \
         + data2[start + 1 - offset: stop - offset: step] * 1.0j
    return d1, d2


def cross_correlate(data1, data2, weigh=True):
    xc = signal.correlate(data1, data2, mode='same')
    ones = np.ones_like(xc)
    if weigh:
        weights = signal.correlate(ones, ones, mode='same')
    else:
        weights = ones
    xc /= weights
    middle_sample = xc.shape[0] // 2
    delay_samples = np.arange(xc.shape[0]) - middle_sample
    delay_seconds = delay_samples * dt

    index_max = np.argmax(np.absolute(xc))
    delay_peak_sam = delay_samples[index_max]
    delay_peak_sec = delay_seconds[index_max]

    fig, ax = plt.subplots(figsize=(8, 4.5))
    ax.plot(delay_samples, np.absolute(xc))
    ax.set(
        title=f" Correlated data of antennas {antenna1} and {antenna2} , at time {time[:2]}:{time[2:]} ,\ nwith peak at offset {delay_peak_sam} samples ",
        xlabel=" Delay [ samples ] ", ylabel=" [ correlator units ] ")
    plt.show()

    return delay_peak_sam, delay_peak_sec


def fx_correlating_interferometer(signal_1, signal_2, num_chan: int = 1024, nrbits: int = 8):
    num_samples = min(len(signal_1), len(signal_2))
    result = np.zeros(num_chan, dtype=np.complex64)
    spectra_added = 0
    for i in range(0, num_samples, num_chan):
        if i + num_chan > num_samples:
            break
        spectrum_1 = np.fft.fft(signal_1[i: i + num_chan], norm='ortho')
        spectrum_2 = np.fft.fft(signal_2[i: i + num_chan], norm='ortho')
        result += spectrum_1 * np.conj(spectrum_2)
        spectra_added += 1
    if spectra_added > 0:
        return np.fft.fftshift(result / spectra_added)
    else:
        raise ValueError('ERROR')


def plot_complex_seq(z, xaxis=None, title=None):
    fig, (ax_abs, ax_phase) = hdfig((2, 1))
    if xaxis is None:
        xlabel, xvalues = 'Channel', np.arange(len(z))
    else:
        xlabel, xvalues = xaxis
        xlabel += '[%s]' % xvalues.unit
    ax_abs.plot(xvalues, np.absolute(z))
    ax_abs.set_ylabel('Amplitude')
    ax_phase.set_xlabel(xlabel)
    ax_phase.set_ylabel('Phase[rad]')
    ax_phase.plot(xvalues, np.angle(z))
    if title:
        fig.suptitle(title)
    plt.show()


freq0 = 1420 * u.MHz
sample_clock = 10 * u.MHz
dt = (1 / sample_clock).to(u.ns)
num_chan = 1024

file1 = ""
file2 = ""
weight = True
time = file1[22:26]
antenna1 = file1[9:11]
antenna2 = file2[9:11]

offset = 0
data1, data2 = read_file(file1, file2, offset)
offset, offset_sec = cross_correlate(data1, data2, weigh)
data1, data2 = read_file(file1, file2, offset)
spectrum = fx_correlating_interferometer(data1, data2, num_chan)
freq_range = np.linspace(freq0 - sample_clock / 2, freq0 + sample_clock / 2, num_chan)
plot_complex_seq(spectrum, xaxis=('Frequency', freq_range),
                 title=f"Antennas {antenna1} and {antenna2} , at time {time[:2]}:{time[2:]} ")
