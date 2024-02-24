import numpy as np
import casacore.tables as ct

def theoretical_noise(ms):

    t = ct.table(ms)
    tt = t.getcol("TIME")[-1]-t.getcol("TIME")[0] # total time
    t = ct.table(ms+"::SPECTRAL_WINDOW")
    bw = np.sum(t.getcol("CHAN_WIDTH")) # bandwidth
    t = ct.table(ms+"::LOFAR_STATION")
    N = len(t.getcol("NAME")) # antennas
    t.close()
    S_sys = 2e3 # from https://science.astron.nl/telescopes/lofar/lofar-system-overview/observing-modes/lofar-imaging-capabilities-and-sensitivity

    sensitivity = S_sys/np.sqrt(N*(N-1)*2*bw*tt)

    return sensitivity