#!/bin/bash
#SBATCH -c 10

#SINGULARITY SETTINGS
SING_BIND=$( python3 $HOME/parse_settings.py --BIND )
SIMG=$( python3 $HOME/parse_settings.py --SIMG )

splitstring=(${PWD//// })
facet=${splitstring[-2]}
echo $facet
facetsplit=(${facet//_/ })
facetnum=${facetsplit[-1]}

jobstring1=$(sbatch ~/scripts/lofar_vlbi_helpers/applycal/applycal_pernight.sh /project/lofarvwf/Share/jdejong/output/ELAIS/ALL_L/dd_solutions/L816272_polrot.h5 L816272)
jobstring2=$(sbatch ~/scripts/lofar_vlbi_helpers/applycal/applycal_pernight.sh /project/lofarvwf/Share/jdejong/output/ELAIS/ALL_L/dd_solutions/L798074_polrot.h5 L798074)
jobstring3=$(sbatch ~/scripts/lofar_vlbi_helpers/applycal/applycal_pernight.sh /project/lofarvwf/Share/jdejong/output/ELAIS/ALL_L/dd_solutions/L686962_polrot.h5 L686962)
jobstring4=$(sbatch ~/scripts/lofar_vlbi_helpers/applycal/applycal_pernight.sh /project/lofarvwf/Share/jdejong/output/ELAIS/ALL_L/dd_solutions/L769393_polrot.h5 L769393)

jobid1=${jobstring1##* }
jobid2=${jobstring2##* }
jobid3=${jobstring3##* }
jobid4=${jobstring4##* }


singularity exec -B ${SING_BIND} ${SIMG} python \
~/scripts/lofar_vlbi_helpers/imaging/split_facets/make_image.py \
--resolution 0.3 \
--facet $facetnum \
--facet_info ../../polygon_info.csv \
--tmpdir

sbatch --dependency=afterok:${jobid1}:${jobid2}:${jobid3}:${jobid4} wsclean.cmd
