import numpy as np
from astropy.io import fits
from argparse import ArgumentParser


def apply_astrometric_offset(ra_deg, dec_deg, dra_arcsec, ddec_arcsec):
    ra_corr = ra_deg + dra_arcsec / (3600 * np.cos(np.deg2rad(dec_deg)))
    dec_corr = dec_deg + ddec_arcsec / 3600
    return ra_corr, dec_corr


astro_corr = {'facet_0': [0.05946628570195543, -0.0016129251495298244],
 'facet_1': [0.05022391789249951, -0.1066768636715118],
 'facet_2': [0.03407505912829386, -0.03411009982083366],
 'facet_3': [0.07227188738382088, -0.009999078235915589],
 'facet_4': [0.06720473698842097, -0.08932750756472731],
 'facet_5': [0.10090003755309106, 0.00827296075329371],
 'facet_6': [0.11817692623464718, -0.02862153998202038],
 'facet_7': [0.14351721039198806, -0.0015657127019549275],
 'facet_8': [-0.038, 0.059],
 'facet_9': [0.12560621226444735, -0.028609785163350887],
 'facet_10': [-0.04901243749487682, -0.04691747916796134],
 'facet_11': [0.14847322382051573, 0.025536232142636325],
 'facet_12': [0.1380395204672594, -0.07577015932045891],
 'facet_13': [0.14691929231050438, -0.014977498498777348],
 'facet_14': [-0.04, 0.0],
 'facet_15': [-0.021022070175534563, 0.002135219675740872],
 'facet_16': [-0.01947329799570496, 0.031473139954782924],
 'facet_17': [-0.07972616220363378, -0.026803019032493176],
 'facet_18': [0.00301016317901193, -0.007836401215820648],
 'facet_19': [-0.01297610764362776, -0.09336083008782439],
 'facet_20': [0.04371218980491071, -0.0439600568472313],
 'facet_21': [0.010370421396686987, -0.10287476871671788],
 'facet_22': [0.02152238163947064, 0.000769476336929609],
 'facet_23': [-0.055719145283096246, -0.04334569820912166]}

flux_scale = {'facet_0': 1.0360480152318066,
 'facet_1': 0.9452574343936895,
 'facet_2': 0.9397039851409544,
 'facet_3': 0.9236253094349279,
 'facet_4': 0.9887729096361219,
 'facet_5': 0.9248756654990453,
 'facet_6': 0.8974996017979143,
 'facet_7': 0.9809772070342063,
 'facet_8': 0.9265141407768479,
 'facet_9': 0.9166625440531079,
 'facet_10': 0.9646637557361158,
 'facet_11': 0.9995111164999619,
 'facet_12': 0.9254074553717331,
 'facet_13': 0.9221699269913316,
 'facet_14': 0.9545237605194641,
 'facet_15': 0.9953084612352147,
 'facet_16': 0.937245571070585,
 'facet_17': 0.9162638034391051,
 'facet_18': 0.9232970312542415,
 'facet_19': 0.9652369985015405,
 'facet_20': 0.9927874649226052,
 'facet_21': 0.9140811630660934,
 'facet_22': 1.0691023210808226,
 'facet_23': 0.8895748245527314}

def parse_args():
    """
    Command line argument parser
    :return: parsed arguments
    """
    parser = ArgumentParser(description='Apply facet scaling and astrometric corrections')
    parser.add_argument('facet', help='fits input file', type=str)
    return parser.parse_args()

if __name__ == '__main__':

    args = parse_args()

    facet = args.facet

    with fits.open(facet, mode="update") as f:
        ra_new, dec_new = apply_astrometric_offset(
            f[0].header["CRVAL1"]%360,
            f[0].header["CRVAL2"],
            astro_corr[facet.split('/')[-1].split('-')[0]][0],
            astro_corr[facet.split('/')[-1].split('-')[0]][1],
        )

        f[0].header["CRVAL1"] = ra_new
        f[0].header["CRVAL2"] = dec_new

        f[0].data *= flux_scale[facet.split('/')[-1].split('-')[0]]

        f.flush()