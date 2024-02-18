from source_properties import MeasureSource
from astropy.table import Table
import numpy as np


def source_values(table, image, idx):

    print(f'test_resolved_{idx}.png')

    T = Table.read(table)
    RA, DEC = T["RA"], T['DEC']

    T = T[(T['Peak_flux'] > 5 * T['Isl_rms']) & (T['S_Code'] == 'M')]

    ra, dec = T[idx]['RA', 'DEC']
    RA = RA[RA != ra]
    DEC = DEC[DEC != dec]

    imsize = 200
    makeim = True

    while makeim:
        S = MeasureSource(fitsfile=image, rms_max_threshold=3, rms=T[idx]['Isl_rms'])
        S.make_cutout((ra, dec), (imsize, imsize))
        S._get_polylist(buff=min(S.peak_flux/S.rms_thresh, 10), ignore_ra=RA, ignore_dec=DEC)
        x, y = S.merged_geometry.boundary.convex_hull.boundary.coords.xy
        if np.max(x)>imsize/1.2 or np.max(y)>imsize/1.2:
            imsize*=1.2
            print('Increase size')
        else:
            makeim=False

    S.make_plot(savefig=f'test_resolved_{idx}.png')

    print('Peak flux image:', str(S.peak_flux), 'Jy/beam')
    print('Peak flux table:', str(T[idx]['Peak_flux']), 'Jy/beam')

    print('Total flux image:', str(S._get_convex_hull_data.sum()/S.beam_pixels), 'Jy')
    print('Total flux table:', str(T[idx]['Total_flux']), 'Jy')


def source_values_compact(table, image, idx):

    T = Table.read(table)
    T = T[(T['Peak_flux'] > 10 * T['Isl_rms']) & (T['S_Code'] == 'S')]
    S = MeasureSource(fitsfile=image, rms_max_threshold=3, max_n_polygons=1, rms=T[idx]['Isl_rms'])

    ra, dec = T[idx]['RA', 'DEC']
    S.make_cutout((ra, dec), (50, 50))
    S._get_polylist(buff=min(S.peak_flux/S.rms_thresh, 10))
    S.make_plot(savefig=f'test_{idx}.png')

    print('Peak flux image:', str(S.peak_flux), 'Jy/beam')
    print('Peak flux table:', str(T[idx]['Peak_flux']), 'Jy/beam')

    print('Total flux image:', str(S._get_convex_hull_data.sum()/S.beam_pixels), 'Jy')
    print('Total flux table:', str(T[idx]['Total_flux']), 'Jy')
