## prefactor_helpers

Most scripts written by Roland Timmerman with additional changes made by Jurjen de Jong.\
Parsets are recycled versions that work well.

Step 0) run download_lta/make_folder_layout.sh to setup layout of folders \
Step 1) move html_calibrator.txt and html_target.txt (from LTA) to Target folder \
Step 2) run download_lta/sbatch_download_series.sh to download the data from the LTA by giving the html.txt \
Step 3) run helper_scripts/findmissingdata.py to check the data \
Step 4) run prefactor_pipeline/run_PFC.sh to calibrate for the calibrator from the calibrator folder \
Step 5) run prefactor_pipeline/run_PFT.sh to calibrate the target from the target folder

Step 6) run the DDF pipeline to obtain a 6" image (solutions/model can be used for higher resolutions), example: ddf_pipeline/ddfrun.sh \
Step 7) run prefactor_pipeline/run_DC.sh to do a delay calibration

See main github page for prefactor --> https://github.com/lofar-astron/prefactor \
Also see --> de Gasperin et al 2019: https://www.aanda.org/articles/aa/pdf/2019/02/aa33867-18.pdf
