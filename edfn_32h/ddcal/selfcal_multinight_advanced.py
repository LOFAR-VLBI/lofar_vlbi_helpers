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
    solint_scalarphase_1 = min(max(deltime/60, np.sqrt(solint)), 3)
    solint_scalarphase_2 = 1.5*solint_scalarphase_1
    solint_scalarphase_3 = 2*solint_scalarphase_1
    solint_scalarphase_4 = 4*solint_scalarphase_1

    solint_complexgain_1 = max(15.0, 15*solint)
    solint_complexgain_2 = 1.5*solint_complexgain_1
    solint_complexgain_3 = 2*solint_complexgain_1
    solint_complexgain_4 = 4*solint_complexgain_1

    # if preapply:
    #     solint_complexgain *= 2
    #     solint_scalarphase *= 2
    cg_cycle_1, cg_cycle_2, cg_cycle_3, cg_cycle_4 = 4, 4, 4, 4

    if solint_complexgain_1/60 > 4:
        cg_cycle_1 = 999
    elif solint_complexgain_1/60 > 3.3:
        solint_complexgain_1 = 240.

    if solint_complexgain_2/60 > 4:
        cg_cycle_2 = 999
    elif solint_complexgain_2/60 > 3.3:
        solint_complexgain_2 = 240.

    if solint_complexgain_3/60 > 4:
        cg_cycle_3 = 999
    elif solint_complexgain_3/60 > 3.3:
        solint_complexgain_3 = 240.

    if solint_complexgain_4/60 > 4:
        cg_cycle_4 = 999
    elif solint_complexgain_4/60 > 3.3:
        solint_complexgain_4 = 240.


    if solint<3:
        smoothness_phase_1 = 10.0
        smoothness_phase_2 = 20.0
        smoothness_phase_3 = 30.0
        smoothness_complex_1 = 20.0
        smoothness_complex_2 = 30.0
    else:
        smoothness_phase_1 = 15.0
        smoothness_phase_2 = 30.0
        smoothness_phase_3 = 40.0
        smoothness_complex_1 = 30.0
        smoothness_complex_2 = 40.0

    print("solint scalarphase 1: "+str(solint_scalarphase_1)+" minutes")
    print("solint scalarphase 2: "+str(solint_scalarphase_2)+" minutes")
    print("solint scalarphase 3: "+str(solint_scalarphase_3)+" minutes")
    print("solint scalarphase 4: "+str(solint_scalarphase_4)+" minutes")

    print("solint scalaramp 1: "+str(solint_complexgain_1)+" minutes")
    print("solint scalaramp 2: "+str(solint_complexgain_2)+" minutes")
    print("solint scalaramp 3: "+str(solint_complexgain_3)+" minutes")
    print("solint scalaramp 4: "+str(solint_complexgain_4)+" minutes")

    if polarization:
        pol=" --makeimage-fullpol "
    else:
        pol=''

    if lowres:
        lr=" --makeimage-ILTlowres-HBA "
    else:
        lr=''

    H5='/project/lofarvwf/Share/jdejong/output/ELAIS/L686962/L686962/ddcal/merged_selfcalcyle009_L686962_6asec.ms.copy.avg.norm.h5'

    script=f"""#!/bin/bash
#SBATCH -c 15
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=jurjendejong@strw.leidenuniv.nl
#SBATCH --constraint=amd

#SINGULARITY SETTINGS
SIMG=$( python3 $HOME/parse_settings.py --SIMG )
BIND=$( python3 $HOME/parse_settings.py --BIND )
echo "SINGULARITY IS $SIMG"
#SCRIPTS
lofar_facet_selfcal=$( python3 $HOME/parse_settings.py --facet_selfcal )
lofar_helpers=$( python3 $HOME/parse_settings.py --lofar_helpers )

singularity exec -B $BIND $SIMG python $lofar_helpers/ms_helpers/remove_flagged_stations.py --overwrite {ms}
singularity exec -B $BIND $SIMG python $lofar_helpers/h5_helpers/find_closest_h5.py --h5_in {H5} --msin {ms}
singularity exec -B $BIND $SIMG python $lofar_helpers/h5_merger.py -in output_h5s/source_0.h5 -out preapply.h5 --propagate_flags -ms {ms} --add_ms_stations
singularity exec -B $BIND $SIMG python $lofar_helpers/ms_helpers/applycal.py --msout {ms}.tmp --h5 preapply.h5 {ms}

rm -rf {ms}
mv {ms}.tmp {ms}

singularity exec -B $BIND $SIMG \\
python $lofar_facet_selfcal \\
-i selfcal \\
--phaseupstations='core' \\
--forwidefield \\
--autofrequencyaverage \\
--update-multiscale \\
--soltypecycles-list="[0,{cg_cycle_1},0,{cg_cycle_2},0,{cg_cycle_3},0,{cg_cycle_4}]" \\
--soltype-list="['scalarphase','scalaramplitude','scalarphase','scalaramplitude','scalarphase','scalaramplitude','scalarphase','scalaramplitude']" \\
--smoothnessconstraint-list="[{smoothness_phase_1},{smoothness_complex_1},{smoothness_phase_1},{smoothness_complex_1},{smoothness_phase_2},{smoothness_complex_2},{smoothness_phase_3},{smoothness_complex_2}]" \\
--smoothnessreffrequency-list="[120.0,0.0,120.0,0.0,120.0,0.0,120.0,0.0]" \\
--smoothnessspectralexponent-list="[-1.0,-1.0,-1.0,-1.0,-1.0,-1.0,-1.0,-1.0]" \\
--solint-list="['{int(solint_scalarphase_1*60)}s','{int(solint_complexgain_1*60)}s','{int(solint_scalarphase_2*60)}s','{int(solint_complexgain_2*60)}s','{int(solint_scalarphase_3*60)}s','{int(solint_complexgain_3*60)}s','{int(solint_scalarphase_4*60)}s','{int(solint_complexgain_4*60)}s']" \\
--uvmin=20000 \\
--imsize=2048 \\
--antennaconstraint-list="[None,None,None,None,'remote','remote','alldutch','alldutch']" \\
--resetsols-list="['alldutchandclosegerman','alldutchandclosegerman','alldutch','alldutch','coreandallbutmostdistantremotes','coreandallbutmostdistantremotes',None,None]" \\
--paralleldeconvolution=1024 \\
--targetcalILT='scalarphase' \\
--stop=12 \\
--flagtimesmeared \\
--compute-phasediffstat \\
--get-diagnostics \\
--helperscriptspath=/project/lofarvwf/Software/lofar_facet_selfcal \\
--helperscriptspathh5merge=/project/lofarvwf/Software/lofar_helpers {pol}{lr}\\
{ms}
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

        tasks = ['mkdir -p '+sourceid+'_selfcal',
                 'mv '+ms+' '+sourceid+'_selfcal',
                 'mv selfcal_script.sh '+sourceid+'_selfcal']
        os.system(' && '.join(tasks))
    print("---RUN---\nfor P in P?????; do cd $P && sbatch selfcal_script.sh && cd ../; done")

