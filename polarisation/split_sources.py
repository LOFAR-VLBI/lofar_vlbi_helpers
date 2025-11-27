import re
from argparse import ArgumentParser
from os import system as run

import astropy.units as u
from astropy.coordinates import SkyCoord
from astropy.table import Table
from pathlib import Path

def extract_lcode(s: str) -> str | None:
    m = re.search(r'\bL\d{6}\b', s)
    return m.group(0) if m else None


def ra_dec_to_iltj(ra_deg: float, dec_deg: float) -> str:
    c = SkyCoord(ra=ra_deg * u.deg, dec=dec_deg * u.deg, frame="icrs")
    ra_hms = c.ra.to_string(unit=u.hour, sep="", precision=2, pad=True)
    dec_dms = c.dec.to_string(unit=u.deg, sep="", precision=1, pad=True, alwayssign=True)
    return f"ILTJ{ra_hms}{dec_dms}"

def parse_args():
    """
    Command line argument parser
    """
    parser = ArgumentParser(description='Split out sources')
    parser.add_argument('--msin', type=str, help='Input MeasurementSet')
    parser.add_argument('--cat', type=str, help='Catalogue')
    return parser.parse_args()

def main() -> int:
    args = parse_args()

    lcode = extract_lcode(args.msin)  # may be None → then omitted in output names

    # Load catalogue and apply simple cuts
    df = Table.read(args.cat, format="fits").to_pandas()
    df = df[(df["Total_flux"] * 1000.0) >= 15.0].copy()  # ≥15 mJy
    if df.empty:
        print("No sources pass flux cut (>=15 mJy).")
        return 0

    df["RA"] = df["RA"] % 360.0  # keep RA in [0, 360)

    for _, src in df.iterrows():
        ra, dec = float(src["RA"]), float(src["DEC"])
        iltj = ra_dec_to_iltj(ra, dec)
        out_name = f"{iltj}_{lcode}.ms" if lcode else f"{iltj}.ms"

        run(f'mkdir -p {iltj}')

        phase_center = f"[{ra}deg,{dec}deg]"
        cmd = [
            "DP3",
            f"msin={args.msin}",
            f"msout={iltj}/{out_name}",
            "phaseshift.type=phaseshift",
            f"phaseshift.phasecenter={phase_center}",
            "avg.type=averager",
            "avg.timeresolution=32",
            "avg.freqresolution=195.36kHz",
            "steps=[phaseshift,beam,avg]",
            "msout.storagemanager=dysco",
            "beam.direction=[]",
            "beam.updateweights=True",
            "beam.type=applybeam"
        ]

        print("Running:", " ".join(cmd))
        run(' '.join(cmd))

    return 0

if __name__ == "__main__":
    main()
