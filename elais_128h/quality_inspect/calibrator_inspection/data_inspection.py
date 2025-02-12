from casacore.tables import table
import numpy as np
from scipy.stats import circstd


def getdata(ms):
    """
    Get calibrator data from MS (DATA * WEIGHTS)

    Args:
        ms: MeasurementSet

    Returns: weighted dataset

    """
    with table(ms, ack=False) as t:
        # DATA: Visibilities are the complex correlation of the signals received by two antennas, needed to reconstruct a sky image
        # WEIGHT_SPECTRUM: Weights corresponding to the visibilities
        data = t.getcol("DATA")
        weight = t.getcol("WEIGHT_SPECTRUM")
        weighted_data = data[:, :, [0,-1]] * weight[:, :, [0,-1]]
        weighted_data[np.isnan(weighted_data)] = 0
        return weighted_data


def data_std(ms):
    """
    Data standard deviation measures

    Args:
        ms: MeasurementSet

    Returns: complex std, circular std on phases, std on amplitudes

    """
    data = getdata(ms)
    data = data[data!=0]
    return data.std(), circstd(np.angle(data)), np.nanstd(np.abs(data))
