## ELAIS-N1 at sub-arcsecond resolutions

Collection of scripts to calibrate LOFAR data for imaging ELAIS-N1 at 0.3", 0.6", and 1.2" with 32 LOFAR observations. 
Note that the paths in the scripts are hardcoded and were written for own usage. 
However, feel free to adjust the code for your own use-cases.

Step 1) run prefactor_pipeline/run_PFC.sh to calibrate for the calibrator data from the calibrator folder \
Step 2) run prefactor_pipeline/run_PFT.sh to calibrate the target data from the target folder \
Step 3) run the DDF pipeline to obtain a 6" image (solutions/model can be used for higher resolutions), example: ../cwl_widefield_imaging/run_ddf.sh \
After DDF need to run helper_scripts/getfreqs_scales.py to get frequency scales used in ddf \
Step 4) run lofar-vlbi-setup/run_DC.sh to make the setup for the delay calibration from lofar-vlbi \
Step 5) run subtract_lotss/subtract_main.sh to subtract 6" LoTSS map from the input data \
Step 6) concat the subtracted output and phase shift to delaycalibrator subtract_lotss/concat.sh \
Step 7) run delayselfcal/delay_facetselfcal_?nights.sh to do a delayselfcal on concattenated file \
Optional: run delayselfcal/tests/test_station.sh to check if there is any corrupt station \
Step 8) run applycal/applycal_multiple*.sh to apply the solutions to the subbands \
Step 9) run imaging/DI_image/wsclean_DI_1asec_?nights.sh to make DD image at 1" as first image (test) \
Step 10) run split_directions/split_directions.sh to split the bright directions to selfcal \
Step 11) run split_directions/concat_dirs.sh to concat the individual subbands per observation \
Step 12) run ddcal/old_scripts/run_selfcal.sh or ddcal/selfcal_multinight_advanced.py to run selfcals in parallel (alternatively ddcal/selfcal.sh for individual selfcals) \
Step 13) run merge/fullmerge.py to merge solutions for best calibrators \
Step 14) run imaging/DD_image/* to do DD imaging \
Step 15) run imaging/split_facets/split_in_facets.sh to image splitted in facets \
Step 16) run imaging/split_facets/make_image.py to image with correct resolution

#### Using
--> https://github.com/lofar-astron/prefactor.git \
--> https://github.com/lmorabit/lofar-vlbi.git \
--> https://github.com/tikk3r/lofar-highres-widefield.git
--> https://github.com/jurjen93/lofar_helpers \
--> https://github.com/rvweeren/lofar_facet_selfcal \