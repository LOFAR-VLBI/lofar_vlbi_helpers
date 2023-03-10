## lofar_vlbi_helpers

My personal scripts to calibrate LOFAR data from the LTA to finish (0.3" resolution)

Step 0) run download_lta/make_folder_layout.sh to setup layout of folders \
Step 1) move html_calibrator.txt and html_target.txt (from LTA) to Target folder \
Step 2) run download_lta/sbatch_download.sh to download the data from the LTA by giving the html.txt \
Step 3) run prefactor_pipeline/run_PFC.sh to calibrate for the calibrator from the calibrator folder \
Step 4) run prefactor_pipeline/run_PFT.sh to calibrate the target from the target folder \
Step 5) run the DDF pipeline to obtain a 6" image (solutions/model can be used for higher resolutions), example: ddf_pipeline/ddfrun.sh \
After DDF need to run helper_scripts/getfreqs_scales.py to get frequency scales used in ddf \
Step 6) run lofar-vlbi-setup/run_DC.sh to make the setup for the delay calibration from lofar-vlbi \
Step 7) run subtract_lotss/subtract_main.sh to subtract 6" LoTSS map from the input data \
Step 8) concat the subtracted output and phase shift to delaycalibrator subtract_lotss/concat.sh \
Step 9) run delayselfcal/delay_facetselfcal.sh to do a delayselfcal on concattenated file \
Optional: run delayselfcal/test_station.sh to check if there is any corrupt station \
Step 10) run applycal/applycal_multiple.sh to apply the solutions to the subbands \
Step 11) run imaging/DI_image/wsclean_DI_1asec_1secaverage.sh to make DD image at 1" as first image (test) \
Step 12) run split_directions/split_directions.sh to split the bright directions to selfcal \
Step 13) run split_directions/concat_dirs.sh to concat the individual subbands per observation \
Step 14) run ddcal/run_selfcal.sh to run selfcals in parallel (alternatively ddcal/selfcal.sh for individual selfcals) \
Step 15) run ddcal/dir_selection.py to do selfcal direction selection \
Step 16) run merge/fullmerge.py to merge solutions for best calibrators \
Step 17) run imaging/DD_image/* to do DD imaging


See main prefactor --> https://github.com/lofar-astron/prefactor \
See main lofar-vlbi pipeline --> https://github.com/lmorabit/lofar-vlbi/blob/master/Delay-Calibration.parset \
Clone lofar-highres-widefield --> ```git clone https://github.com/tikk3r/lofar-highres-widefield.git```

Also see --> de Gasperin et al 2019: https://www.aanda.org/articles/aa/pdf/2019/02/aa33867-18.pdf
