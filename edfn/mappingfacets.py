import pandas as pd
import casacore.tables as pt
import numpy as np
import os
from glob import glob


for LNUM in ['L727112', 'L720380']:
    for n in range(41):
        FACETNUM = f"{n}"
        try:
            ms = glob(f"/project/lofarvwf/Share/jdejong/output/EUCLID/edfn/{LNUM}/facetsubtract/outdir/facet_{FACETNUM}_{LNUM}.ms")[0]

            df = pd.read_csv("/project/lofarvwf/Share/jdejong/output/EUCLID/edfn_centre/extra_selfcals/polygon_info.csv")
            t = pt.table(f"{ms}/FIELD")

            coord=df['poly_center'].str.replace('[','').str.replace(']','').str.replace('deg','').str.split(',')

            ra = coord.str[0].astype(float)
            dec = coord.str[1].astype(float)

            phasedir = np.degrees(t.getcol("PHASE_DIR"))%360
            ms_ra = phasedir[0][0][0]
            ms_dec = phasedir[0][0][1]

            closest_index_dec = (dec.astype(float) - ms_dec).abs().idxmin()
            closest_index_ra = (ra.astype(float) - ms_ra).abs().idxmin()

            if closest_index_dec==closest_index_ra:
                print(f'mv {ms} /project/lofarvwf/Share/jdejong/output/EUCLID/edfn/{LNUM}/facetsubtract/outdir/facet_{closest_index_dec}_{LNUM}_EDFN.ms')
                os.system(f'mv {ms} /project/lofarvwf/Share/jdejong/output/EUCLID/edfn/{LNUM}/facetsubtract/outdir/facet_{closest_index_dec}_{LNUM}_EDFN.ms')
        except:
            pass