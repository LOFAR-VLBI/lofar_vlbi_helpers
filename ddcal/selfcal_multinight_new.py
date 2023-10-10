from glob import glob
import os
import inspect
import pandas as pd
import casacore.tables as ct
import numpy as np

ELAIS=True
polarization=False
lowres=True

def make_selfcal_script(solint, ms):
    """

    :param solint: solution interval in minutes
    :param ms: measurement set
    :return:
    """

    t = ct.table(ms, readonly=True, ack=False)
    time = np.unique(t.getcol('TIME'))
    t.close()
    # total_obs_time = (time.max()-time.min())//60
    deltime = np.abs(time[1]-time[0])

    # solint_scalarphase = np.rint(solint*60/deltime)
    # solint_complexgain = np.rint(solint*60*10/deltime)

    solint_scalarphase = min(max(deltime/60, round(solint/2, 3)), 30.) # solint in minutes
    solint_complexgain = max(15., 15*solint)
    cg_cycle = 3

    if solint_complexgain/60 > 4:
        cg_cycle = 999
    elif solint_complexgain/60 > 3:
        solint_complexgain = 240.

    print("solint scalarphase: "+str(solint_scalarphase)+" minutes")
    print("solint complexgain: "+str(solint_complexgain)+" minutes")
    if cg_cycle == 999:
        print("solint complexgain: Over 3 hours --> REMOVED")

    if ELAIS: #TODO: Replace with distance from phase center function
        for P in ['P20075', 'P16883', 'P17010', 'P17565', 'P19951', 'P23167', 'P48367', 'P57108',
                  'P50716', 'P50735', 'P58902', 'P54920', 'P53426', 'P50892', 'P46921', 'P40952',
                  'P31933', 'P27648', 'P23872']:
            if P in ms:
                flagtimesmeared = '--flagtimesmeared '
            else:
                flagtimesmeared=''
    else:
        flagtimesmeared = ''

    if polarization:
        pol=" --makeimage-fullpol "
    else:
        pol=''

    if lowres:
        lr=" --makeimage-ILTlowres-HBA "
    else:
        lr=''


    script=f"""#!/bin/bash
#SBATCH -c 12
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=jurjendejong@strw.leidenuniv.nl
#SBATCH --constraint=amd
#SBATCH -t 72:00:00

#SINGULARITY SETTINGS
SIMG=$( python3 $HOME/parse_settings.py --SIMG )
BIND=$( python3 $HOME/parse_settings.py --BIND )
echo "SINGULARITY IS $SIMG"
#SCRIPTS
lofar_facet_selfcal=$( python3 $HOME/parse_settings.py --facet_selfcal )

singularity exec -B $BIND $SIMG \\
python $lofar_facet_selfcal \\
-i selfcal \\
--phaseupstations='core' \\
--forwidefield \\
--useaoflagger \\
--autofrequencyaverage \\
--update-multiscale \\
--soltypecycles-list="[0,{cg_cycle}]" \\
--soltype-list="['scalarphase','scalarcomplexgain']" \\
--smoothnessconstraint-list="[10.0,5.0]" \\
--smoothnessreffrequency-list="[120.0,0.0]" \\
--smoothnessspectralexponent-list="[-1.0,-1.0]" \\
--smoothnessrefdistance-list="[0.0,0.0]" \\
--solint-list="['{int(solint_scalarphase*60)}s','{int(solint_complexgain*60)}s']" \\
--uvmin=20000 \\
--imsize=2048 \\
--paralleldeconvolution=1024 \\
--targetcalILT='scalarphase' \\
--stop=12 \\
--helperscriptspath=/project/lofarvwf/Software/lofar_facet_selfcal \\
--helperscriptspathh5merge=/project/lofarvwf/Software/lofar_helpers {flagtimesmeared}{pol}{lr}\\
*.ms
"""

    f = open("selfcal_script.sh", "w")
    f.write(script)
    f.close()


if __name__ == "__main__":

    script_dir = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))

    directions = set([f.split("_")[2].split('.')[0] for f in glob('*L??????_P?????.ms')])

    phasediff_output = 'phasediff_output.csv'
    phasediff = pd.read_csv(phasediff_output)
    phasediff['direction'] = phasediff.source.str.split('/').str[0]

    for d in directions:

        solint = phasediff[phasediff['source'].str.contains(d)].best_solint.min()
        make_selfcal_script(solint, glob("*L??????_P?????.ms")[0])

        print(d)
        tasks = ['mkdir -p '+d,
                 'mv *L??????_'+d+'.ms '+d,
                 'mv selfcal_script.sh '+d]
        # os.system(' && '.join(tasks))
    print("---RUN---\nfor P in P?????; do cd $P && sbatch selfcal_script.sh && cd ../; done")