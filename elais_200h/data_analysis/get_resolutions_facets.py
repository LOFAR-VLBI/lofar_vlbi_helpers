from glob import glob
from astropy.io import fits
import numpy as np

def get_rms(image_data):
    """
    from Cyril Tasse/kMS

    :param image_data: image data array
    :return: rms (noise measure)
    """

    from past.utils import old_div

    maskSup = 1e-7
    m = image_data[np.abs(image_data) > maskSup]
    rmsold = np.std(m)
    diff = 1e-1
    cut = 3.
    med = np.median(m)
    for _ in range(10):
        ind = np.where(np.abs(m - med) < rmsold * cut)[0]
        rms = np.std(m[ind])
        if np.abs(old_div((rms - rmsold), rmsold)) < diff: break
        rmsold = rms
    return rms

facets = glob("/project/lofarvwf/Public/jdejong/ELAIS_200h/facet_*/0.3asec/*image-pb.fits")
for f in sorted(facets):
    print(f.split("/")[-1].split("-")[0])
    fts = fits.open(f)
    print(f"{round(fts[0].header['BMAJ']*3600, 2)} x {round(fts[0].header['BMIN']*3600, 2)}")
    rms = get_rms(fts[0].data)
    print(f"RMS: {rms}")
    print()