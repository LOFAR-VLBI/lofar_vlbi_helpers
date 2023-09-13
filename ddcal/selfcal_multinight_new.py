from glob import glob
import os
import inspect
import pandas as pd

def make_selfcal_script(solint):

    solint_scalarphase = solint
    solint_complexgain = solint*10

    if solint_complexgain/60 > 4:
        cg_cycle = 999
    else:
        cg_cycle = 3

    script=f"""
#!/bin/bash
#SBATCH -c 12
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=jurjendejong@strw.leidenuniv.nl
#SBATCH --constraint=amd

MS=$1

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
--smoothnessreffrequency-list="[120.0,0.0] \\
--smoothnessspectralexponent-list="[-1.0,-1.0]" \\
--smoothnessrefdistance-list="[0.0,0.0]" \\
--solint-list="[{solint_scalarphase},{solint_complexgain}]" \\
--uvmin=20000 \\
--imsize=2048 \\
--paralleldeconvolution=1024 \\
--makeimage-ILTlowres-HBA \\
--targetcalILT='scalarphase' \\
--stop=12 \\
--makeimage-fullpol \\
--helperscriptspath=/home/lofarvwf-jdejong/scripts/lofar_facet_selfcal \\
--helperscriptspathh5merge=/home/lofarvwf-jdejong/scripts/lofar_helpers \\
$MS
    """

    f = open("selfcal_script.sh", "w")
    f.write(script)
    f.close()


if __name__ == "__main__":

    script_dir = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))

    directions = set([f.split("_")[1].split('.')[0] for f in glob('L??????_P*.ms')])


    for d in directions:

        phasediff_output = 'phasediff_output.csv'
        phasediff = pd.read_csv(phasediff_output)
        phasediff['direction'] = phasediff.source.str.split('/').str[0]
        solint = phasediff[phasediff['direction']==d].best_solint.mean().values[0]
        make_selfcal_script(solint)

        print(d)
        tasks = ['mkdir -p '+d,
                 'mv L??????_'+d+'.ms '+d,
                 'mv selfcal_script.sh '+d,
                 'cd '+d,
                 f'sbatch selfcal_script.sh '+d,
                 'cd ../']
        print(' && '.join(tasks))
        os.system(' && '.join(tasks))