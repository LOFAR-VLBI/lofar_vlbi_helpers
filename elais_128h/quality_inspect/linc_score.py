from scipy.stats import circstd
import tables
import numpy as np

calsol = "cal_solutions.h5"

def get_circstd(calsol):
    H = tables.open_file(calsol)
    polalign = H.root.calibrator.polalign
    ants_indices = [idx for idx, a in enumerate(polalign.ant[:] )
            if 'CS' not in a.decode('utf8') and 'RS' not in a.decode('utf8') and 'DE' not in a.decode('utf8')]
    score = np.mean([circstd(polalign.val[:, a_idx, :, 1], nan_policy='omit') for a_idx in ants_indices])
    print(calsol, score)

