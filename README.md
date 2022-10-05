## lofar_vlbi_helpers

My personal scripts to calibrate LOFAR data from the LTA to finish (0.3" resolution)

Step 0) run download_lta/make_folder_layout.sh to setup layout of folders \
Step 1) move html_calibrator.txt and html_target.txt (from LTA) to Target folder \
Step 2) run download_lta/sbatch_download_series.sh to download the data from the LTA by giving the html.txt \
Step 3) run helper_scripts/findmissingdata.py to check the data \
Step 4) run prefactor_pipeline/run_PFC.sh to calibrate for the calibrator from the calibrator folder \
Step 5) run prefactor_pipeline/run_PFT.sh to calibrate the target from the target folder \
Step 6) run the DDF pipeline to obtain a 6" image (solutions/model can be used for higher resolutions), example: ddf_pipeline/ddfrun.sh \
After DDF need to run helper_scripts/getfreqs_scales.py to get frequency scales used in ddf \
Step 7) run prefactor_pipeline/run_DC.sh to make the setup for the delay calibration from lofar-vlbi \
Step 8) run subtract_lotss/subtract_main.sh to subtract 6" LoTSS map from the input data \
Step 9) run delayselfcal/delay_facetselfcal.sh to do a delayselfcal \
Step 10) ...

See main prefactor --> https://github.com/lofar-astron/prefactor \
See main lofar-vlbi pipeline --> https://github.com/lmorabit/lofar-vlbi/blob/master/Delay-Calibration.parset \
Clone lofar-highres-widefield --> ```git clone https://github.com/tikk3r/lofar-highres-widefield.git```

Also see --> de Gasperin et al 2019: https://www.aanda.org/articles/aa/pdf/2019/02/aa33867-18.pdf
