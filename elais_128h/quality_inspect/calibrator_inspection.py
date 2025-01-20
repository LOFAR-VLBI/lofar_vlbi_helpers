from casacore.tables import table

ms = "ILTJ161212.29+552303.8_sub6asec_L686962_SB001_uv_12CFFDDA9t.concat.ms"

t = table(ms)

# DATA: Visibilities are the complex correlation of the signals received by two antennas, needed to reconstruct a sky image
# WEIGHT_SPECTRUM: Weights corresponding to the visibilities
weighted_data = t.getcol("DATA") * t.getcol("WEIGHT_SPECTRUM")
weighted_data_xx = weighted_data[:, :, 0]
