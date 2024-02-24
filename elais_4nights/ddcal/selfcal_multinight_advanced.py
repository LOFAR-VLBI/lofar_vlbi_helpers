from glob import glob
import os
import inspect
import pandas as pd
import casacore.tables as ct
import numpy as np

polarization=False
lowres=True

def make_selfcal_script(solint, ms, preapply):
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
    if preapply:
        solint_complexgain *= 5
        solint_scalarphase *= 5
    cg_cycle = 3

    if solint_complexgain/60 > 4:
        cg_cycle = 999
    elif solint_complexgain/60 > 3:
        solint_complexgain = 240.

    if solint<1:
        smoothness_complex = 5.0
    else:
        smoothness_complex = 10.0

    print("solint scalarphase: "+str(solint_scalarphase)+" minutes")
    print("solint complexgain: "+str(solint_complexgain)+" minutes")
    if cg_cycle == 999:
        print("solint complexgain: Over 3 hours --> REMOVED")

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
--soltypecycles-list="[0,0,{cg_cycle}]" \\
--soltype-list="['scalarphase','scalarphase','scalarcomplexgain']" \\
--smoothnessconstraint-list="[15.0,40.0,{smoothness_complex}]" \\
--smoothnessreffrequency-list="[120.0,120.0,0.0]" \\
--smoothnessspectralexponent-list="[-1.0,-1.0,-1.0]" \\
--solint-list="['{int(solint_scalarphase*60)}s','{int(2*solint_scalarphase*60)}s','{int(solint_complexgain*60)}s']" \\
--uvmin=20000 \\
--imsize=2048 \\
--resetsols-list="['alldutch',None,None]" \\
--paralleldeconvolution=1024 \\
--targetcalILT='scalarphase' \\
--stop=12 \\
--flagtimesmeared \\
--helperscriptspath=/project/lofarvwf/Software/lofar_facet_selfcal \\
--helperscriptspathh5merge=/project/lofarvwf/Software/lofar_helpers {pol}{lr}\\
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
        make_selfcal_script(solint, glob("*L??????_P?????.ms")[0], True)

        print(d)
        tasks = ['mkdir -p '+d,
                 'mv *L??????_'+d+'.ms '+d,
                 'mv selfcal_script.sh '+d]
        # os.system(' && '.join(tasks))
    print("---RUN---\nfor P in P?????; do cd $P && sbatch selfcal_script.sh && cd ../; done")