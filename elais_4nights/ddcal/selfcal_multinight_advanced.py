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

    deltime = np.abs(time[1]-time[0])

    # solint in minutes
    solint_scalarphase = max(deltime/60, solint)
    solint_complexgain = max(20., 120*solint)

    if preapply:
        solint_complexgain *= 5
        solint_scalarphase *= 5
    cg_cycle = 3

    if solint_complexgain/60 > 4:
        cg_cycle = 999
        print("solint complexgain: Over 3 hours --> REMOVED")
    elif solint_complexgain/60 > 3:
        solint_complexgain = 240.

    if solint<1:
        smoothness_complex = 10.0
    else:
        smoothness_complex = 20.0

    print("solint scalarphase: "+str(solint_scalarphase)+" minutes")
    print("solint complexgain: "+str(solint_complexgain)+" minutes")

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
--compute-phasediffstat \\
--get-diagnostics \\
--helperscriptspath=/project/lofarvwf/Software/lofar_facet_selfcal \\
--helperscriptspathh5merge=/project/lofarvwf/Software/lofar_helpers {pol}{lr}\\
*.ms
"""

    f = open("selfcal_script.sh", "w")
    f.write(script)
    f.close()


if __name__ == "__main__":


    mss = glob('*.ms')

    phasediff_output = '/project/lofarvwf/Share/jdejong/output/ELAIS/final_dd_selection.csv'
    phasediff = pd.read_csv(phasediff_output)

    for ms in mss:

        print(ms)

        sourceid = ms.split("_")[0]

        solint = phasediff[phasediff['Source_id'].str.split('_').str[0] == sourceid].best_solint.min()
        make_selfcal_script(solint, ms, False)

        tasks = ['mkdir -p '+sourceid+'_selfcal_3',
                 'mv '+ms+' '+sourceid+'_selfcal_3',
                 'mv selfcal_script.sh '+sourceid+'_selfcal_3']
        os.system(' && '.join(tasks))
    print("---RUN---\nfor P in P?????; do cd $P && sbatch selfcal_script.sh && cd ../; done")