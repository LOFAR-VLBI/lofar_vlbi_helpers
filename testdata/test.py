from analyse.catalogue.source_properties import MeasureSource
from astropy.table import Table
import numpy as np


def source_values(idx):

    T = Table.read("facet_19_source_catalog_final.fits")
    T = T[(T['Peak_flux'] > 5 * T['Isl_rms']) & (T['S_Code'] == 'M')]

    ra, dec = T[idx]['RA', 'DEC']
    imsize = 150
    makeim = True

    while makeim:
        S = MeasureSource(fitsfile='facet_19.fits', rms_max_threshold=3, rms=T[idx]['Isl_rms'])
        S.make_cutout((ra, dec), (imsize, imsize))
        S._get_polylist(buff=min(S.peak_flux/S.rms, 10))
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


def source_values_compact(idx):

    T = Table.read("facet_19_source_catalog_final.fits")
    T = T[(T['Peak_flux'] > 10 * T['Isl_rms']) & (T['S_Code'] == 'S')]
    S = MeasureSource(fitsfile='facet_19.fits', rms_max_threshold=3, max_n_polygons=1, rms=T[idx]['Isl_rms'])

    ra, dec = T[idx]['RA', 'DEC']
    S.make_cutout((ra, dec), (50, 50))
    S._get_polylist(buff=min(S.peak_flux/S.rms, 10))
    S.make_plot(savefig=f'test_{idx}.png')

    print('Peak flux image:', str(S.peak_flux), 'Jy/beam')
    print('Peak flux table:', str(T[idx]['Peak_flux']), 'Jy/beam')

    print('Total flux image:', str(S._get_convex_hull_data.sum()/S.beam_pixels), 'Jy')
    print('Total flux table:', str(T[idx]['Total_flux']), 'Jy')
