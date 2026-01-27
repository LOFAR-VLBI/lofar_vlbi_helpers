import argparse
from os import path
import numpy as np
from casacore.tables import table
import subprocess
from glob import glob

def main():
    parser = argparse.ArgumentParser(description="Run LOFAR-VLBI/plot_field.")
    parser.add_argument("--ms", nargs='+', required=True, help="Path to the MeasurementSet (MS)")

    args = parser.parse_args()

    # Expand glob and take first entry
    matches = args.ms
    if not matches:
        raise RuntimeError(f"No MS files match pattern: {args.ms}")
    ms = path.abspath(matches[0])

    t = table(ms + "::FIELD")
    phase_dir = np.degrees(t.getcol("PHASE_DIR") % (2 * np.pi)).squeeze()

    ra = phase_dir[0]
    dec = phase_dir[1]

    print(f"MeasurementSet --> {ms}\nRA={ra}\nDEC={dec}")

    # Build command
    cmd = ["lofar-vlbi-plot", "--RA", str(ra), "--DEC", str(dec),"--continue_no_lotss", "--force"]

    try:
        subprocess.run(cmd, check=True)
    except subprocess.CalledProcessError as e:
        print(f"Error running lofar-vlbi-plot: {e}")

if __name__ == "__main__":
    main()
